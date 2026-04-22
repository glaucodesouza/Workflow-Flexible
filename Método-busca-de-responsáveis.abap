  METHOD if_rsm_badi_static_rule~responsibility_rule.

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
      lv_workflow_id  TYPE sww_wiid,
      lv_dummy,
      vl_nivel        TYPE int1,
      vl_code         TYPE zde_code_aprov,
      lt_nivelcode    TYPE ty_nivelcode_tt,
      lv_ja_executado TYPE char3. " Check for recursive call

    " ---------------------------------------------------------
    " RECURSIVIDADE?
    " Check for recursive call
    " ---------------------------------------------------------
    " Verificação de chamada Recursiva
    " Se sim, deverá sair (RETURN) a partir da segunda execução.
    CALL FUNCTION 'ZWFF2060'
      IMPORTING
        e_ja_executado = lv_ja_executado
      EXCEPTIONS
        OTHERS         = 1.

    " ---------------------------------------------------------
    " IF: Is this method called recursivelly ?
    " IF: already executed before=YES?
    " Exit from this method, using RETURN
    " ---------------------------------------------------------
    IF sy-subrc = 0 AND lv_ja_executado IS NOT INITIAL.

      " Fill the Recursivity control of count of times (sum, just for curiosity)
      ADD 1 TO lv_ja_executado.
      CALL FUNCTION 'ZWFF2059'
        EXPORTING
          i_ja_executado = lv_ja_executado.
      IF lv_ja_executado > 1 .
        " Exit this method
        " No more needed execution of this method
        " Because it was executed already recursivelly
        RETURN.
      ENDIF.

      " ---------------------------------------------------------
      " WHEN it is the very First execution
      " We can execute it yes
      " ---------------------------------------------------------
    ELSE. " Check for recursive call

      " Export multiple variables to memory under a key
      lv_ja_executado = '1'.
      ""exportar" para saber se já fi executada a busca de resp.
      CALL FUNCTION 'ZWFF2059'
        EXPORTING
          i_ja_executado = lv_ja_executado.

      TRY.

          " 1-Read QMNUM (from App Responsability Rule config.)
          DATA ls_parameter_name_value_pair LIKE LINE OF it_parameter_name_value_pair.
          READ TABLE it_parameter_name_value_pair WITH KEY name = 'NOTA_MANUT' INTO ls_parameter_name_value_pair.
          IF sy-subrc = 0.
            FIELD-SYMBOLS : <fs_parameter_value_tab> TYPE i_maintenancenotification.
            ASSIGN ls_parameter_name_value_pair-value->* TO <fs_parameter_value_tab>.

            IF <fs_parameter_value_tab> IS ASSIGNED.
              " Get document number
              DATA(lv_document_number) = <fs_parameter_value_tab>-maintenancenotification.

              " Get group
              SELECT SINGLE maintenanceplannergroup
                FROM i_pmnotifmaintenancedata
                INTO @DATA(vl_ingrp)
               WHERE maintenancenotification = @lv_document_number.
            ENDIF.
          ENDIF.

          " 2-XML, Find LEVEL + CODE
          " from XML:
          "   vl_nivel (level)
          "   vl_code
          "   lt_nivelcode (level)
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
          zcl_wf_zportal_util=>buscar_aprov_wf_nota_manut(
            EXPORTING
              i_code   = vl_code                     " Code Aprovação
              i_ingrp  = vl_ingrp                    " Grupo de planejamento
            IMPORTING
              e_agents = et_agents               " List of approve Users
          ).

        CATCH cx_root.

      ENDTRY.

      "If no approvers were found, insert ERROR in WF Log
      READ TABLE et_agents INDEX 1 TRANSPORTING NO FIELDS.
      IF sy-subrc IS NOT INITIAL.
        MESSAGE e060(zwf) INTO lv_dummy WITH vl_code vl_ingrp.

        DATA: ls_error_message     TYPE scx_t100key,
              lv_message_attribute TYPE char20.

        ls_error_message = VALUE #( msgid = sy-msgid msgno = sy-msgno attr1 = sy-msgv1 attr2 = sy-msgv2 ).

        RAISE EXCEPTION TYPE cx_rsm_agt_detn_tech_exception "cx_rsm_runtime_error
          EXPORTING
            textid = ls_error_message.

      ENDIF.

    ENDIF. " Check for recursive call

  ENDMETHOD.
