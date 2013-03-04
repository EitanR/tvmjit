#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.

(!assign json (!call (!index tvm "dofile") "json/grammar.tp"))
(!assign parse (!index json "parse"))

(!call (!index tvm "dofile") "TAP.tp")

(!call plan 60)

(!call ok (!call parse "   [ true ]   ") "true")
(!call ok (!call parse "   [ false ]  ") "false")
(!call ok (!call parse "   [ null ]   ") "nil")
(!call ok (!call parse "   [ -42 ]    ") "-42")
(!call ok (!call parse "   [ 3.14 ]   ") "3.14")
(!call ok (!call parse "   [ \"str\" ]  ") "str")
(!call ok (!call parse "   [ \"\" ]  ") "empty string")
(!call ok (!call parse "   [ \"\\\"\" ]  ") "quote")
(!call ok (!call parse "   [ \"\\\\\" ]  ") "backslash")
(!call ok (!call parse "   [ \"a\\tb\" ]  ") "tab")
(!call ok (!call parse "   [ \"a\\u20acb\" ]  ") "\\u")
(!call ok (!call parse "   []   ") "empty array")
(!call ok (!call parse "   {}   ") "empty object")
(!call ok (!call parse "   [ 1, 2, 3, 4 ] ") "array")
(!call ok (!call parse "\
    {\
        \"a\" : 1,\
        \"b\" : 2,\
        \"c\" : 3\
    }\
") "object")

(!call nok (!call parse " [] extra  "))
(!call nok (!call parse " true      "))
(!call nok (!call parse " [1, bare] "))
(!call nok (!call parse " [ 1; 2 ]  "))
(!call nok (!call parse " { \"a\":1 ; "))
(!call nok (!call parse " { \"a\";1   "))
(!call nok (!call parse " { bare:1  "))

(!call ok (!call parse "\
    {\
        \"Image\": {\
            \"Width\":  800,\
            \"Height\": 600,\
            \"Title\":  \"View from 15th Floor\",\
            \"Thumbnail\": {\
                \"Url\":    \"http://www.example.com/image/481989943\",\
                \"Height\": 125,\
                \"Width\":  \"100\"\
            },\
            \"IDs\": [116, 943, 234, 38793]\
        }\
    }\
"))

(!call ok (!call parse "\
    [\
        {\
            \"precision\": \"zip\",\
            \"Latitude\":  37.7668,\
            \"Longitude\": -122.3959,\
            \"Address\":   \"\",\
            \"City\":      \"SAN FRANCISCO\",\
            \"State\":     \"CA\",\
            \"Zip\":       \"94107\",\
            \"Country\":   \"US\"\
        },\
        {\
            \"precision\": \"zip\",\
            \"Latitude\":  37.371991,\
            \"Longitude\": -122.026020,\
            \"Address\":   \"\",\
            \"City\":      \"SUNNYVALE\",\
            \"State\":     \"CA\",\
            \"Zip\":       \"94085\",\
            \"Country\":   \"US\"\
        }\
    ]\
"))

(!loop i 1 3 1
        (!let fname (!mconcat "../t/json/test/pass" i ".json"))
        (!let f (!call (!index io "open") fname))
        (!let content (!callmeth f read "*a"))
        (!callmeth f close)
        (!call ok (!call parse content) fname)
)

(!let TODO (15:!true 17:!true 18: !true 26: !true))
(!loop i 1 33 1
        (!let fname (!mconcat "../t/json/test/fail" i ".json"))
        (!let f (!call (!index io "open") fname))
        (!let content (!callmeth f read "*a"))
        (!callmeth f close)
        (!let r (!call parse content))
        (!if (!index TODO i) (!call todo content 1))
        (!call nok r fname)
)

