  METHOD if_rsm_badi_static_rule~responsibility_rule.

    DATA:
      lv_workflow_id TYPE sww_wiid,
      lv_dummy.

    TYPES:
      BEGIN OF ty_nivelcode,
        nivel        TYPE i,
        code         TYPE string,
        artifact_id  TYPE string,
        runtime_stat TYPE string,
      END OF ty_nivelcode .

    TYPES:
      ty_nivelcode_tt TYPE STANDARD TABLE OF ty_nivelcode WITH DEFAULT KEY .

    DATA:
      vl_nivel     TYPE int1,
      vl_code      TYPE zde_code_aprov,
      lt_nivelcode TYPE ty_nivelcode_tt.

    TRY.

        " 1-Ler EBELN
        DATA ls_parameter_name_value_pair LIKE LINE OF it_parameter_name_value_pair.
        READ TABLE it_parameter_name_value_pair WITH KEY name = 'PLANO_MANUT' INTO ls_parameter_name_value_pair.
        IF sy-subrc = 0.
          FIELD-SYMBOLS : <fs_parameter_value_tab> TYPE a_maintenanceorder."ANY TABLE.
          ASSIGN ls_parameter_name_value_pair-value->* TO <fs_parameter_value_tab>.

          IF <fs_parameter_value_tab> IS ASSIGNED.
            " Proceed to use the parameter value - a table of values.
            DATA(lv_document_number) = <fs_parameter_value_tab>-maintenanceorder.

            " pegar o primeiro Grupo de planejamento válido
            SELECT wpgrp
              UP TO 1 ROWS
              FROM mpos
              INTO @DATA(lv_wpgrp)
              ORDER BY PRIMARY KEY.
            ENDSELECT.
          ENDIF.

        ENDIF.

        " 2-XML, Encontra NIVEL/nivel + CODE
        " Buscar no XML:
        "   vl_nivel
        "   vl_code
        "   lt_nivelcode
        zcl_wf_zportal_util=>calcular_code_passo_atual(
          EXPORTING
            i_wf_key      = CONV string( lv_document_number )
            i_wf_scenario = 'WS99900021'
          IMPORTING
            e_workflow_id = lv_workflow_id
            e_step        = vl_nivel
            e_code        = vl_code
            e_nivelcode   = lt_nivelcode ).

        " 3-GET APPROVERS for current code
        zcl_wf_zportal_util=>buscar_aprov_wf_plano_manut(
          EXPORTING
            i_code   = vl_code                     " Code Aprovação
            i_wpgrp  = lv_wpgrp                    " Grupo de planejamento
          IMPORTING
            e_agents = et_agents               " List of approve Users
        ).

      CATCH cx_root.

    ENDTRY.

    READ TABLE et_agents INDEX 1 TRANSPORTING NO FIELDS.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e059(zwf) INTO lv_dummy WITH vl_code lv_wpgrp.
      "lv_fb_name = 'BADi GET_APPROVERS'(001).

      DATA: ls_error_message     TYPE scx_t100key,
            lv_message_attribute TYPE char20.

      ls_error_message = VALUE #( msgid = sy-msgid msgno = sy-msgno attr1 = sy-msgv1 attr2 = sy-msgv2 ).

      RAISE EXCEPTION TYPE cx_rsm_agt_detn_tech_exception "cx_rsm_runtime_error
        EXPORTING
          textid = ls_error_message.

    ENDIF.

  ENDMETHOD.
