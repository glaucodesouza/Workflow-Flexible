# Botão GOS nas transações standard

Implementar BADI GOS_MULT_PUBLISH como abaixo:  
Adicionar filtro da BADI tipo: WF_OVERVIEW (Síntese workflow)  
Adicionar codificação como abaixo:  

    METHOD if_ex_gos_mult_publish~add_objects.
      FIELD-SYMBOLS: <fs_lporb> TYPE sibflporb,
                     <fs_new>   TYPE sibflporb.
  
      DATA: lv_instid TYPE sibfboriid.
  
      LOOP AT ct_lporb ASSIGNING <fs_lporb> WHERE catid  = 'BO' AND
                                                  typeid = 'BUS2100002'.
  
        "map key from FIPP (BUKRS,BELNR,GJAHR) to (BELNR,BUKRS,GJAHR)      
        "CONCATENATE
        "<fs_lporb>-instid+04(10)   "BELNR
        "<fs_lporb>-instid+00(04)   "BUKRS
        "<fs_lporb>-instid+14(04)   "GJAHR
        "INTO lv_instid RESPECTING BLANKS.
        lv_instid = <fs_lporb>-instid.
        APPEND INITIAL LINE TO ct_lporb ASSIGNING <fs_new>.
        <fs_new>-instid = lv_instid.
        <fs_new>-catid  = 'CL'.
        <fs_new>-typeid = 'CL_WLF_BWF_DOCUMENT_UPDATES'.
      ENDLOOP.
      SORT ct_lporb.
      DELETE ADJACENT DUPLICATES FROM ct_lporb.
    ENDMETHOD.
