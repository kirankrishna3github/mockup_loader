class lcl_mockup_stub_factory_test definition final
  for testing
  duration short
  risk level harmless.

  private section.
    methods main_test_stub for testing.
    methods generate_params for testing.
    methods connect_method for testing.
    methods build_config for testing.
endclass.

*class zcl_mockup_loader_stub_factory definition local friends lcl_mockup_stub_factory_test.

class lcl_test_base definition final.
  public section.
    class-methods main_test
      importing lv_factory_classname type seoclsname.
endclass.
class lcl_test_base implementation.
  method main_test.

    data lo_dc type ref to zcl_mockup_loader_stub_factory.
    data li_if type ref to zif_mockup_loader_stub_dummy.
    data lo_ml type ref to zcl_mockup_loader.
    data lt_exp type flighttab.
    data lo_ex type ref to zcx_mockup_loader_error.

    try.
      lo_ml  = zcl_mockup_loader=>create(
        i_type = 'MIME'
        i_path = 'ZMOCKUP_LOADER_EXAMPLE' ).

      create object lo_dc type (lv_factory_classname)
        exporting
          io_ml_instance = lo_ml
          i_interface_name = 'ZIF_MOCKUP_LOADER_STUB_DUMMY'.

      lo_dc->connect_method(
        i_sift_param      = 'I_CONNID'
        i_mock_tab_key    = 'CONNID'
        i_method_name     = 'TAB_RETURN'
        i_mock_name       = 'EXAMPLE/sflight' ).

      lo_dc->connect_method(
        i_method_name  = 'TAB_EXPORT'
        i_mock_name    = 'EXAMPLE/sflight'
        i_output_param = 'ETAB' ).

      lo_dc->connect_method(
        i_method_name  = 'TAB_CHANGE'
        i_mock_name    = 'EXAMPLE/sflight'
        i_output_param = 'CTAB' ).

      li_if ?= lo_dc->generate_stub( ).

      lo_ml->load_data(
        exporting
          i_obj    = 'EXAMPLE/sflight'
          i_strict = abap_false
        importing
          e_container = lt_exp ).

      delete lt_exp index 2.
      data lt_res type flighttab.
      lt_res = li_if->tab_return( i_connid = '1000' ).
      cl_abap_unit_assert=>assert_equals( act = lt_res exp = lt_exp ).

      lo_ml->load_data(
        exporting
          i_obj    = 'EXAMPLE/sflight'
          i_strict = abap_false
        importing
          e_container = lt_exp ).

      clear lt_res.
      li_if->tab_export( exporting i_connid = '1000' importing etab = lt_res ).
      cl_abap_unit_assert=>assert_equals( act = lt_res exp = lt_exp ).

      clear lt_res.
      li_if->tab_change( exporting i_connid = '1000' changing ctab = lt_res ).
      cl_abap_unit_assert=>assert_equals( act = lt_res exp = lt_exp ).

    catch zcx_mockup_loader_error into lo_ex.
      cl_abap_unit_assert=>fail( ).
    endtry.

  endmethod.

endclass.

define assert_excode.
  cl_abap_unit_assert=>assert_not_initial( act = lo_ex ).
  cl_abap_unit_assert=>assert_equals( exp = &1 act = lo_ex->code ).
end-of-definition.

class lcl_mockup_stub_factory_test implementation.

  method main_test_stub.
    lcl_test_base=>main_test( 'ZCL_MOCKUP_LOADER_STUB_FACTORY' ).
  endmethod.

  method generate_params.

    data ld_if type ref to cl_abap_objectdescr.
    data ld_type type ref to cl_abap_typedescr.
    data lt_act type abap_parmbind_tab.
    data lt_exp type abap_parmbind_tab.
    data par like line of lt_exp.

    ld_if ?= cl_abap_typedescr=>describe_by_name( 'ZIF_MOCKUP_LOADER_STUB_DUMMY' ).

    lt_act = zcl_mockup_loader_stub_factory=>generate_params(
      id_if_desc = ld_if
      i_method   = 'GEN_PARAM_TARGET' ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_act ) exp = 4 ).

    clear par.
    read table lt_act with key name = 'P1' into par.
    cl_abap_unit_assert=>assert_equals( act = par-kind exp = 'E' ).
    ld_type ?= cl_abap_typedescr=>describe_by_data_ref( par-value ).
    cl_abap_unit_assert=>assert_equals( act = ld_type->type_kind exp = cl_abap_typedescr=>typekind_int ).

    clear par.
    read table lt_act with key name = 'P2' into par.
    cl_abap_unit_assert=>assert_equals( act = par-kind exp = 'E' ).
    ld_type ?= cl_abap_typedescr=>describe_by_data_ref( par-value ).
    cl_abap_unit_assert=>assert_equals( act = ld_type->type_kind exp = cl_abap_typedescr=>typekind_char ).

    clear par.
    read table lt_act with key name = 'P3' into par.
    cl_abap_unit_assert=>assert_equals( act = par-kind exp = 'E' ).
    ld_type ?= cl_abap_typedescr=>describe_by_data_ref( par-value ).
    cl_abap_unit_assert=>assert_equals( act = ld_type->type_kind exp = cl_abap_typedescr=>typekind_char ).

    clear par.
    read table lt_act with key name = 'CTAB' into par.
    cl_abap_unit_assert=>assert_equals( act = par-kind exp = 'C' ).
    ld_type ?= cl_abap_typedescr=>describe_by_data_ref( par-value ).
    cl_abap_unit_assert=>assert_equals( act = ld_type->type_kind exp = cl_abap_typedescr=>typekind_table ).
    cl_abap_unit_assert=>assert_equals( act = ld_type->absolute_name exp = '\TYPE=FLIGHTTAB' ).

  endmethod.

  method connect_method.
    data lo_dc type ref to zcl_mockup_loader_stub_factory.
    data lo_ml type ref to zcl_mockup_loader.
    data lo_ex type ref to zcx_mockup_loader_error.

    try.

    catch zcx_mockup_loader_error into lo_ex.
      cl_abap_unit_assert=>fail( ).
    endtry.

    try.
      lo_ml  = zcl_mockup_loader=>create(
        i_type = 'MIME'
        i_path = 'ZMOCKUP_LOADER_EXAMPLE' ).

      create object lo_dc
        exporting
          io_ml_instance = lo_ml
          i_interface_name = 'ZIF_MOCKUP_LOADER_STUB_DUMMY'.

      lo_dc->connect_method(
        i_method_name     = 'TAB_RETURN'
        i_mock_name       = 'EXAMPLE/sflight' ).
      lo_dc->connect_method(
        i_method_name     = 'TAB_RETURN'
        i_mock_name       = 'EXAMPLE/sflight' ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'MC'.

  endmethod.

  method build_config.
    data ld_if       type ref to cl_abap_objectdescr.
    data ls_conf     type zcl_mockup_loader_stub_base=>ty_mock_config.
    data ls_conf_act type zcl_mockup_loader_stub_base=>ty_mock_config.
    data lo_ex type ref to zcx_mockup_loader_error.

    ld_if ?= cl_abap_typedescr=>describe_by_name( 'ZIF_MOCKUP_LOADER_STUB_DUMMY' ).

    try.
      clear: lo_ex, ls_conf.
      ls_conf-method_name = 'TAB_RETURN'.
      ls_conf-mock_name   = 'EXAMPLE/sflight'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
      cl_abap_unit_assert=>fail( ).
    endtry.
    cl_abap_unit_assert=>assert_equals( act = ls_conf_act-output_param exp = 'RTAB' ).
    cl_abap_unit_assert=>assert_equals( act = ls_conf_act-output_pkind exp = 'R' ).
    cl_abap_unit_assert=>assert_bound( act = ls_conf_act-output_type ).

    try. " method missing
      clear: lo_ex, ls_conf.
      ls_conf-mock_name   = 'EXAMPLE/sflight'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'MM'.

    try. " mock missing
      clear: lo_ex, ls_conf.
      ls_conf-method_name = 'TAB_RETURN'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'MK'.

    try. " sift incomplete
      clear: lo_ex, ls_conf.
      ls_conf-method_name = 'TAB_RETURN'.
      ls_conf-mock_name   = 'EXAMPLE/sflight'.
      ls_conf-sift_param  = 'I_CONNID'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'MS'.

    try. " sift incomplete
      clear: lo_ex, ls_conf.
      ls_conf-method_name  = 'TAB_RETURN'.
      ls_conf-mock_name    = 'EXAMPLE/sflight'.
      ls_conf-mock_tab_key = 'CONNID'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'MS'.

    try. " sift incomplete
      clear: lo_ex, ls_conf.
      ls_conf-method_name  = '???'.
      ls_conf-mock_name    = 'EXAMPLE/sflight'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'MF'.

    try. " sift not found
      clear: lo_ex, ls_conf.
      ls_conf-method_name  = 'TAB_RETURN'.
      ls_conf-mock_name    = 'EXAMPLE/sflight'.
      ls_conf-sift_param   = 'X_CONNID'.
      ls_conf-mock_tab_key = 'CONNID'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'PF'.

    try. " sift has wrong type
      clear: lo_ex, ls_conf.
      ls_conf-method_name  = 'WRONG_SIFT'.
      ls_conf-mock_name    = 'EXAMPLE/sflight'.
      ls_conf-sift_param   = 'I_CONNID'.
      ls_conf-mock_tab_key = 'CONNID'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'PE'.

    try. " no return
      clear: lo_ex, ls_conf.
      ls_conf-method_name = 'TAB_EXPORT'.
      ls_conf-mock_name   = 'EXAMPLE/sflight'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'MR'.

    try. " no param
      clear: lo_ex, ls_conf.
      ls_conf-method_name  = 'TAB_RETURN'.
      ls_conf-mock_name    = 'EXAMPLE/sflight'.
      ls_conf-output_param = '???'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'PF'.

    try. " no param
      clear: lo_ex, ls_conf.
      ls_conf-method_name  = 'TAB_RETURN'.
      ls_conf-mock_name    = 'EXAMPLE/sflight'.
      ls_conf-output_param = 'I_CONNID'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'PI'.

    try. " no param
      clear: lo_ex, ls_conf.
      ls_conf-method_name  = 'WRONG_RETURN'.
      ls_conf-mock_name    = 'EXAMPLE/sflight'.
      ls_conf_act = zcl_mockup_loader_stub_factory=>build_config(
        id_if_desc = ld_if
        i_config   = ls_conf ).
    catch zcx_mockup_loader_error into lo_ex.
    endtry.
    assert_excode 'PT'.

  endmethod.

endclass.
