# Mockup Loader for ABAP unit testing

*Version: 2.0.0-beta3 ([history of changes](/changelog.txt))*

## Major changes in version 2

- `zcl_mockup_loader` split into several classes to separate loading, store and utils.
- parsing logic was separated into [abap_data_parser](https://github.com/sbcgua/abap_data_parser) package which is now a prerequisite. Sorry for this. We believe this is for good.
- `zcl_mockup_loader` is not a singleton anymore. Must be instantiated with `create` method. `zcl_mockup_loader_store` remained the singleton.
- VBA zip compiler depreciated, see below 'Conversion to Excel' section.
- Interface stubbing :tada:. See 'Data delivery' section.

## Contents

<!-- start toc -->

- [Synopsis](#synopsis)
- [Data delivery](#data-delivery)
- [Installation](#installation)
- [Load source redirection](#load-source-redirection)
- [Conversion from Excel](#conversion-from-excel)
- [Reference](#reference)
- [Examples](#examples)
- [Contributors](#contributors)
- [Publications](#publications)
- [License](#license)

<!-- end toc -->

## Synopsis

The tool is created to simplify data preparation/loading for SAP ABAP unit tests. In one of our projects we had to prepare a lot of table data for unit tests. For example, a set of content from `BKPF`, `BSEG`, `BSET` tables (FI document). The output of the methods under test is also often a table or a complex structure. 

Hard-coding all of that data was not an option - too much to code, difficult to maintain and terrible code readability. So we decided to write a tool which would get the data from TAB delimited `.txt` files, which, in turn, would be prepared in Excel in a convenient way. Certain objectives were set:

- all the test data should be combined together in one file (zip)
- ... and uploaded to SAP - test data should be a part of the dev package (W3MI binary object would fit)
- loading routine should identify the file structure (fields) automatically and verify its compatibility with a target container (structure or table) 
- it should also be able to safely skip fields, missing in `.txt` file, if required (*non strict* mode) e.g. when processing structures (like FI document) with too many fields, most of which are irrelevant to a specific test.

```abap
" Test class (o_ml is mockup_loader instance)
...
o_ml->load_data( " Load test data (structure) from mockup
  exporting
    i_obj       = 'TEST1/bkpf'
  importing
    e_container = ls_bkpf ).

o_ml->load_data( " Load test data (table) from mockup
  exporting
    i_obj       = 'TEST1/bseg'
    i_strict    = abap_false
  importing
    e_container = lt_bseg ).
...

" Call to the code-under-test
o_test_object->some_processing(
  exporting
    i_bkpf   = ls_bkpf
    it_bseg  = lt_bseg ).

assert_equals(...).
```

The first part of the code takes TAB delimited text file `bkpf.txt` in TEST1 directory of ZIP file uploaded as binary object via SMW0 transaction...

```
BUKRS BELNR GJAHR BUZEI BSCHL KOART ...
1000  10    2015  1     40    S     ...
1000  10    2015  2     50    S     ...
```

... and puts it (with proper ALPHA exits and etc) to an internal table with `BSEG` line type.  

On-the-fly data filtering is supported. For more information see [REFERENCE.md](docs/REFERENCE.md).

## Data delivery

### Interface stubbing

Since 2.0.0 mockup loader supports generating of interface stubs. :tada:

It creates an instance object which implements the given interface where one or more methods retrive the data from the mockup. Optional filtering is supported, thus one of the method parameters is treated as the value to filter the mockup data by the given key field.

```abap
  data lo_factory type ref to zcl_mockup_loader_stub_factory.
  data lo_ml      type ref to zcl_mockup_loader.
  
  lo_ml = zcl_mockup_loader=>create(
    i_type = 'MIME'
    i_path = 'ZMOCKUP_LOADER_EXAMPLE' ). " <INIT YOUR MOCKUP>

  create object lo_factory
    exporting
      io_ml_instance   = lo_ml
      i_interface_name = 'ZIF_MOCKUP_LOADER_STUB_DUMMY'. " <YOUR INTERFACE TO STUB>

  " Connect one or MANY methods to respective mockups 
  lo_factory->connect_method(
    i_method_name     = 'TAB_RETURN'         " <METHOD TO STUB>
    i_mock_name       = 'EXAMPLE/sflight' ). " <MOCK PATH>

  data li_ifstub type ref to ZIF_MOCKUP_LOADER_STUB_DUMMY. 
  li_ifstub ?= lo_factory->generate_stub( ).

  " Pass the stub to code-under-test, the effect is:
  ...
  data lt_res type flighttab.
  lt_res = li_ifstub->tab_return( i_connid = '1000' ).
  " lt_res contains the mock data ...
```

... and with filtering

```abap
  ...
  lo_factory->connect_method(
    i_method_name     = 'TAB_RETURN'         " <METHOD TO STUB>
    i_sift_param      = 'I_CONNID'           " <FILTERING PARAM>
    i_mock_tab_key    = 'CONNID'             " <MOCK HEADER FIELD>
    i_mock_name       = 'EXAMPLE/sflight' ). " <MOCK PATH>
  ...
```
This will result in the data set where key field `CONNID` will be equal to `I_CONNID` parameter actually passed to interface call.

`Returning`, `exporting` and `chainging` parameters are supported. For more information see [REFERENCE.md](docs/REFERENCE.md).

In addition, forwarding calls to another object (implementing same interface) is supported. For example if some of accessor methods must be connected to mocks and some others were implemented manually in a supprting test (or real production) class. See [REFERENCE.md](docs/REFERENCE.md).

### Store/Retrieve

**Disclaimer**: *There is an opinion that adding test-related code to the production code is a 'code smell'. I sincerely agree in general. If the code was designed to use e.g. accessor interfaces from the beginning this is good. Still 'store' functionality can be useful for older pieces of code to be tested without much refactoring.*

Some code is quite difficult to test when it has a *db select* in the middle. Of course, good code design would assume isolation of DB operations from business logic code, but it is not always possible (or was not done in proper time). So we needed to create a way to substitute *selects* in code to a simple call, which would take the prepared test data instead if test environment was identified. We came up with the solution we called `store`. 
   
```abap
" Test class (o_mls is mockup_loader_STORE instance)
...
o_mls->store( " Store some data with 'BKPF' label
  exporting
    i_name = 'BKPF'
    i_data = ls_bkpf ). " One line structure
...

" Working class method
...
if is_test_env = abap_false. " Production environment detected
  select ... from db ...

else.                        " Test environment detected
  zcl_mockup_loader_store=>retrieve(
    exporting i_name  = 'BKPF'
    importing e_data  = ls_fi_doc_header
    exceptions others = 4 ).
endif. 

if sy-subrc is not initial.
  " Data not selected -> do error handling
endif.

```

In case of multiple test cases it can also be convenient to load a number of table records and then **filter** it based on some key field, available in the working code. This option is also possible:

``` abap
" Test class
...
o_mls->store( " Store some data with 'BKPF' label
  exporting
    i_name   = 'BKPF'
    i_tabkey = 'BELNR'    " Key field for the stored table
    i_data   = lt_bkpf ). " Table with MANY different documents
...

" Working class method
...
if is_test_env = abap_false. " Production environment detected
  " Do DB selects here 

else.                        " Test environment detected
  zcl_mockup_loader_store=>retrieve(
    exporting
      i_name  = 'BKPF'
      i_sift  = l_document_number " <<< Filter key from real local variable
    importing
      e_data  = ls_fi_doc_header  " Still a flat structure here
    exceptions others = 4 ).
endif. 

if sy-subrc is not initial.
  " Data not selected -> error handling
endif.

```  

As the final result we can perform completely dynamic unit tests, covering most of code, including *DB select* related code **without** actually accessing the database. Of course, it is not only the mockup loader which ensures that. This requires accurate design of the project code, separating DB selection and processing code. The mockup loader and "store" functionality makes it more convenient.

The `zcl_mockup_loader` has a *shortcut* method `load_and_store` to load data to the store directly without technical variables. For more information see [REFERENCE.md](docs/REFERENCE.md).

![data flow](docs/illustration.png)

Some design facts about the `store`:

- The store class `ZCL_MOCKUP_LOADER_STORE` is designed as a singleton class. So it is initiated once in a test class and the exists in one instance only.
- `RETRIEVE` method, which takes data from the "Store" is **static**. It is assumed to be called from "production" code instead of *DB selects*. It acquires the instance inside and throws **non-class** based exception on error. This is made to avoid the necessity to handle test-related exceptions, irrelevant to the main code, and also to be able to catch the exception as `SY-SUBRC` value. `SY-SUBRC` can be checked later similarly to regular DB select. So the interference with the main code is minimal. 

## Installation

The most convenient way to install the package is to use [abapGit](https://github.com/larshp/abapGit) - it is easily installed itself and then a couple of click to clone the repo into the system. There is also an option for offline installation - download the repo as zip file and import it with abapGit. Unit test execution is always recommended after-installation.

Dependencies (to install before mockup loader):
- [text2tab](https://github.com/sbcgua/abap_data_parser) - tab-delimited text parser (was a part of *mockup loader* but now a separate reusable tool). Mandatory prerequisite.
- [abap_w3mi_poller](https://github.com/sbcgua/abap_w3mi_poller) - *optional* - enables 'Upload to MIME' button in `ZMOCKUP_LOADER_SWSRC`. The mockup loader **can be compiled without this** package (the call is dynamic).

## Load source redirection

Zipped mockups slug is supposed to be uploaded as a MIME object via SMW0. However, during data or test creation, it is more convenient (and faster) to read local file. Also not to upload 'draft' test data to the system.

`i_type` and `i_path` are the parameters to the `create` method to define the 'normal' mockup source. To **temporarily** switch to another source you can use the transaction `ZMOCKUP_LOADER_SWSRC`. It will initialize SET/GET parameters  `ZMOCKUP_LOADER_STYPE` and `ZMOCKUP_LOADER_SPATH(MIME)` which will **override** defaults for the current session only.

![switch source](docs/switch.png)

N.B. Type change in the selection screen immediately changes the parameters in session memory, no run is required ('enter' should be pressed though after manual text fields change to trigger `on screen`). `Get SU3` reads param values from user master (useful when you work on the same project for some time). `Upload to MIME` uploads the file to MIME storage (requires [abap_w3mi_poller](https://github.com/sbcgua/abap_w3mi_poller) to be installed).

## Conversion from Excel

You may have a lot of data prepared in Excel files. Many files, many sheets in each. Although Ctrl+C in Excel actually copies TAB-delimited text, which greatly simplifies the matter for minor cases, it is boring and time consuming to copy all the test cases to text. Here are special tools to simplify this workflow. Briefly: they take directory of excel files with mockup data and convert them into format compatible with mockup loader.

- [mockup compiler](https://github.com/sbcgua/mockup_compiler) - ABAP implementation, requires [abap2xlsx](https://github.com/ivanfemia/abap2xlsx) installed.
- [mockup compiler JS](https://github.com/sbcgua/mockup-compiler-js) - java script implemenation, requires nodejs environment at the developer's machine.

See [EXCEL2TXT.md](docs/EXCEL2TXT.md) for more info.

![compile zip slug](docs/compiler.png)

## Reference

Complete reference of classes and methods can be found in [REFERENCE.md](docs/REFERENCE.md). 

## Examples

- Have a look at the howto section in the project [Wiki](../../wiki).
- A simple example can be found in [/src/zmockup_loader_example.prog.abap](/src/zmockup_loader_example.prog.abap).

## Contributors

Major contributors are described in [CONTRIBUTORS.md](/CONTRIBUTORS.md). You are welcomed to suggest ideas and code improvements ! :) Let's make ABAP development more convenient.

## Publications

- [Unit testing mockup loader for ABAP @SCN](http://scn.sap.com/community/abap/blog/2015/11/12/unit-testing-mockup-loader-for-abap)
- [How to do convenient multicase unit tests with zmockup_loader @SCN](http://scn.sap.com/community/abap/blog/2016/03/20/how-to-do-convenient-multicase-test-with-zmockuploader)
- [zmockup_loader and unit tests with interface stubbing](https://blogs.sap.com/?p=712675)
- [zmockup_loader: unit test data preparation flow](https://blogs.sap.com/?p=714903)

## License

The code is licensed under MIT License. Please see the [LICENSE](/LICENSE) for details.
