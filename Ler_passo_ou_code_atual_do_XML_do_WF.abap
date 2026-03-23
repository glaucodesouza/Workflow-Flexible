  METHOD calcular_code_passo_atual.

*  IV_WF_KEY
*  IV_WF_SCENARIO
*  EV_STEP
*  EV_CODE
*  ET_NIVELCODE

    DATA:
      lv_xml_steps   TYPE i,
      lv_log_steps   TYPE i,
      lv_scenario_id TYPE swd_wfd_id,
      lv_object_id   TYPE sibfboriid,
      ls_message     TYPE swf_t100ms.

    " Resultado da identificação do passo e aprovador
    TYPES: BEGIN OF ty_current_step,
             step_index      TYPE i,        " 1, 2, 3...
             runtime_status  TYPE string,   " status do passo atual (ex.: NOT_STARTED, IN_PROGRESS...)
             approver_code   TYPE string,   " conteúdo de <name> (ex.: 'SU')
             approver_textid TYPE string,   " atributo textId de <name>
             artifact_id     TYPE string,   " atributo artifactId do <activity>
           END OF ty_current_step.

    DATA ls_current TYPE ty_current_step.

    e_step = 0.

    lv_object_id = i_wf_key.
    lv_scenario_id = i_wf_scenario.

    DATA(lo_wf_inst) = cl_swf_flex_def_factory=>wf_inst_handler( ).
    DATA(lt_instances) = lo_wf_inst->get_workflow_instances(
      EXPORTING
        iv_scenario_id = lv_scenario_id
        iv_appl_obj_id = lv_object_id
        iv_is_draft    = abap_false
        iv_context     = || ).

    SORT lt_instances BY workflow_id DESCENDING.
    READ TABLE lt_instances REFERENCE INTO DATA(lcl_instance) INDEX 1.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_swf_flex_ifs_exception.
    ENDIF.

    e_workflow_id = lcl_instance->workflow_id.

    "XML MAIN do Worfklow
    DATA(lo_ixml) = cl_ixml=>create( ).
    DATA(lo_stream_factory) = lo_ixml->create_stream_factory( ).
    DATA(lo_document) = lo_ixml->create_document( ).

    IF lo_ixml->create_parser(
      document = lo_document
      stream_factory = lo_stream_factory
      istream = lo_stream_factory->create_istream_xstring( string = lcl_instance->xmlresource ) )->parse( ) <> 0.

      RAISE EXCEPTION TYPE cx_swf_flex_ifs_exception.
    ENDIF.

    " 1) Passo atual + code
    ls_current-step_index = 0.
    ls_current-approver_code = ''.
    ls_current-approver_textid = ''.
    ls_current-artifact_id = ''.
    ls_current-runtime_status = ''.

    DATA(lo_pf_itr) = lo_document->create_iterator( ).
    lo_pf_itr->set_filter( lo_document->create_filter_name_ns( name = 'processFlow' ) ).
    DATA(lo_pf) = lo_pf_itr->get_next( ).

    WHILE lo_pf IS BOUND.
      DATA(lo_act_itr) = lo_pf->create_iterator( ).
      lo_act_itr->set_filter( lo_document->create_filter_name_ns( name = 'activity' ) ).
      DATA(lo_act) = lo_act_itr->get_next( ).

      DATA(lv_completed_skipped) = 0.

      WHILE lo_act IS BOUND.
        DATA(lo_attr) = lo_act->get_attributes( ).
        DATA(lo_rs)   = lo_attr->get_named_item_ns( name = 'runtimeStatus' ).
        DATA(lv_rs)   = COND string( WHEN lo_rs IS BOUND THEN lo_rs->get_value( ) ELSE '' ).

        CASE lv_rs.
          WHEN 'CANCELLED'.
            lv_completed_skipped = 0.
          WHEN 'COMPLETED' OR 'SKIPPED'.
            lv_completed_skipped = lv_completed_skipped + 1.
          WHEN OTHERS.
            " nada
        ENDCASE.

        lo_act = lo_act_itr->get_next( ).
      ENDWHILE.

      DATA(lv_target_index) = lv_completed_skipped + 1.

      lo_act_itr = lo_pf->create_iterator( ).
      lo_act_itr->set_filter( lo_document->create_filter_name_ns( name = 'activity' ) ).
      lo_act = lo_act_itr->get_next( ).

      DATA(lv_index) = 0.
      WHILE lo_act IS BOUND.
        lv_index = lv_index + 1.
        IF lv_index = lv_target_index.
          DATA(lo_attr2) = lo_act->get_attributes( ).
          DATA(lo_artid) = lo_attr2->get_named_item_ns( name = 'artifactId' ).
          IF lo_artid IS BOUND.
            ls_current-artifact_id = lo_artid->get_value( ).
          ENDIF.

          DATA(lo_rs2) = lo_attr2->get_named_item_ns( name = 'runtimeStatus' ).
          IF lo_rs2 IS BOUND.
            ls_current-runtime_status = lo_rs2->get_value( ).
          ENDIF.

          DATA(lo_name_itr) = lo_act->create_iterator( ).
          lo_name_itr->set_filter( lo_document->create_filter_name_ns( name = 'name' ) ).
          DATA(lo_name) = lo_name_itr->get_next( ).
          IF lo_name IS BOUND.
            ls_current-approver_code = lo_name->get_value( ).
          ENDIF.

          EXIT.
        ENDIF.
        lo_act = lo_act_itr->get_next( ).
      ENDWHILE.

      ls_current-step_index = lv_target_index.

      lo_pf = lo_pf_itr->get_next( ).
    ENDWHILE.

    e_step = ls_current-step_index.
    e_code = ls_current-approver_code.

    "2) Tabela completa (todos os steps)
    DATA lt_all_steps TYPE STANDARD TABLE OF ty_nivelcode WITH EMPTY KEY.

    DATA(lo_pf_itr_all) = lo_document->create_iterator( ).
    lo_pf_itr_all->set_filter( lo_document->create_filter_name_ns( name = 'processFlow' ) ).
    DATA(lo_pf_all) = lo_pf_itr_all->get_next( ).

    WHILE lo_pf_all IS BOUND.
      DATA(lo_act_itr_all) = lo_pf_all->create_iterator( ).
      lo_act_itr_all->set_filter( lo_document->create_filter_name_ns( name = 'activity' ) ).
      DATA(lo_act_all) = lo_act_itr_all->get_next( ).

      DATA(lv_idx_all) = 0.
      WHILE lo_act_all IS BOUND.
        lv_idx_all = lv_idx_all + 1.
        DATA ls_entry TYPE ty_nivelcode.
        ls_entry-nivel = lv_idx_all.

        DATA(lo_attr_all) = lo_act_all->get_attributes( ).
        IF lo_attr_all IS BOUND.
          DATA(lo_artid_all) = lo_attr_all->get_named_item_ns( name = 'artifactId' ).
          IF lo_artid_all IS BOUND.
            ls_entry-artifact_id = lo_artid_all->get_value( ).
          ENDIF.
          DATA(lo_rs_all) = lo_attr_all->get_named_item_ns( name = 'runtimeStatus' ).
          IF lo_rs_all IS BOUND.
            ls_entry-runtime_stat = lo_rs_all->get_value( ).
          ENDIF.
        ENDIF.

        DATA(lo_name_itr_all) = lo_act_all->create_iterator( ).
        lo_name_itr_all->set_filter( lo_document->create_filter_name_ns( name = 'name' ) ).
        DATA(lo_name_all) = lo_name_itr_all->get_next( ).
        IF lo_name_all IS BOUND.
          ls_entry-code = lo_name_all->get_value( ).
          SHIFT ls_entry-code LEFT DELETING LEADING space.
          SHIFT ls_entry-code RIGHT DELETING TRAILING space.
        ENDIF.

        APPEND ls_entry TO lt_all_steps.
        lo_act_all = lo_act_itr_all->get_next( ).
      ENDWHILE.

      lo_pf_all = lo_pf_itr_all->get_next( ).
    ENDWHILE.

    e_nivelcode[] = lt_all_steps[].

  ENDMETHOD.
