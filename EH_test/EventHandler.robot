*** Settings ***
Suite Setup       Run keyword    Connect To Database    ${DB}    ${DBName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
...               AND    Open Server Connection and Log In
Suite Teardown    Run Keywords    Close All Connections
...               AND    Disconnect From Database
Resource          ../Resources/EH_Variables.txt
Library           ../Resources/Tx_log_util.py
Library           requests
Library           Collections
Library           String
Library           RequestsLibrary
Library           Selenium2Library
Library           OperatingSystem
Library           JSONLibrary
Library           SoapLibrary
Library           DatabaseLibrary
Library           SSHLibrary
Library           DateTime

*** Test Cases ***
Rest_MDFlow
    [Tags]    TC001
    ${Random Numbers}    Generate Random String    4    [NUMBERS]
    log    ${Random Numbers}
    Create Session    Test    ${rest_url}
    ${headers}    Create Dictionary    transactionOrder=${Random Numbers}    transactionId=tr_id${Random Numbers}    messageSource=REST_SINGLE
    log    ${headers}
    ${json}=    OperatingSystem.Get file    ${RestRequest_JSONPATH}
    ${json_object}=    evaluate    json.loads('''${json}''')    json
    ${json_string}=    evaluate    json.dumps(${json_object}) \    json
    ${response}=    RequestsLibrary.Post Request    Test    uri=    data=${json_string}    headers=${headers}
    ${statusCode}    Set Variable    ${response.status_code}
    ${var}    Convert To Integer    ${statusCode}
    Should Be Equal As Strings    ${var}    201
    sleep    40s
    log    ${response.headers}
    ${GetMessageID}    Split String    ${response.headers.get('Location')}    /
    ${MESSAGE_ID}    Set Variable    ${GetMessageID[8]}
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    /bne-event-handler/bne/v1/jobs/${JOB_ID}/messages/${MESSAGE_ID}/deliveryStatus    expected_status=Anything
    Status Should Be    200
    sleep    40s
    ###DbValidation###
    sleep    40s
    ${MESSAGE_EVENT}=    Query    SELECT JOB_ID, EVENT_ID, MESSAGE_ID, BULK_ID, MSISDN, EVENT_DELIVERY_STATUS, FAILURE_REASON FROM MESSAGE_EVENT where JOB_ID='${JOB_ID}' and MESSAGE_ID = '${MESSAGE_ID}'
    Log To Console    ${MESSAGE_EVENT}
    ${MESSAGE_ID}=    Get From List    ${MESSAGE_EVENT[0]}    2
    ${EVENT_DELIVERY_STATUS}=    Get From List    ${MESSAGE_EVENT[0]}    5
    Should Be Equal As Strings    ${EVENT_DELIVERY_STATUS}    DeliveredToNetwork
    ###LogValidation###
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check1}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path}    ${eh-data-txn}    ${pod_folder}    ${MESSAGE_ID}
    Log    ${log_check1}
    ${log_list1}=    Split String    ${log_check1}[1]    separator=,
    Should Be Equal As Strings    ${log_list1[17]}    ${MESSAGE_ID}
    Should Be Equal As Strings    ${log_list1[14]}    DeliveredToNetwork

CorrectURL
    [Tags]    TC002
    ${queryResults}=    query    SELECT max(event_id) FROM message_event where job_id='${JOB_ID}'
    log    ${queryResults[0][0]}
    ${latest_index}=    Set Variable    ${queryResults[0][0]}
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    /bne-event-handler/bne/v1/jobs/${JOB_ID}/message-events    params=page_size=${PAGE_SIZE}&from_index=${latest_index}    expected_status=Anything
    Status Should Be    200

IncorrectURL
    [Tags]    TC003
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    /bne-event-handler/bne/v1/jobs//message-events    params=page_size=${PAGE_SIZE}&from_index=${FROM_INDEX}    expected_status=Anything
    Status Should Be    404
    ${Err_Msg}=    Convert To Bytes    The server has not found anything matching the request URI
    Should Contain    ${resp.content}    ${Err_Msg}

Negative page size value
    [Tags]    TC004
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=page_size=${NEG_VALUE}&from_index=${FROM_INDEX}    expected_status=Anything
    Status Should Be    400
    Should Be Equal    ${resp.json()}[requestError][serviceException][exceptionMsgId]    SVC2000
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][0]    The requested query parameters are not valid. Please provide a valid Query parameters
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][1]    30001
    Should Be Equal    ${resp.json()}[requestError][serviceException][text] \    The following error occurred. %1. Error code is %2 \

Invalid Query parameter
    [Tags]    TC005
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=pagesize=${PAGE_SIZE}&fromindex=${FROM_INDEX}    expected_status=Anything
    Status Should Be    400
    Should Be Equal    ${resp.json()}[requestError][serviceException][exceptionMsgId]    SVC2000
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][0]    The requested query parameters are not valid. Please provide a valid Query parameters
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][1]    30001
    Should Be Equal    ${resp.json()}[requestError][serviceException][text]    The following error occurred. %1. Error code is %2

Negative form_Index value
    [Tags]    TC006
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=pagesize=${PAGE_SIZE}&fromindex=${NEG_VALUE}    expected_status=Anything
    Status Should Be    400
    Should Be Equal    ${resp.json()}[requestError][serviceException][exceptionMsgId]    SVC2000
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][0]    The requested query parameters are not valid. Please provide a valid Query parameters
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][1]    30001
    Should Be Equal    ${resp.json()}[requestError][serviceException][text]    The following error occurred. %1. Error code is %2

Unknown Job id
    [Tags]    TC007
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${UNKNOWNJOB_URI}    params=page_size=${PAGE_SIZE}&from_index=${FROM_INDEX}    expected_status=Anything
    Status Should Be    400

Invalid page size value
    [Tags]    TC008
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=page_size=${INVALID_VALUE}&from_index=${FROM_INDEX}    expected_status=Anything
    Status Should Be    400
    Should Be Equal    ${resp.json()}[requestError][serviceException][exceptionMsgId]    SVC2000
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][0]    The provided query parameter values are not numeric. Please provide valid numbers
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][1]    30002
    Should Be Equal    ${resp.json()}[requestError][serviceException][text] \    The following error occurred. %1. Error code is %2 \

Invalid from_Index value
    [Tags]    TC009
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=page_size=2&from_index=${NEG_VALUE}    expected_status=Anything
    Status Should Be    400
    Should Be Equal    ${resp.json()}[requestError][serviceException][exceptionMsgId]    SVC2000
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][0]    The requested query parameters are not valid. Please provide a valid Query parameters
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][1]    30001
    Should Be Equal    ${resp.json()}[requestError][serviceException][text]    The following error occurred. %1. Error code is %2

Default from_Index value
    [Tags]    TC010
    ${queryResults}=    query    select LAST_QUERY_INDEX from QUERY_EVENT_INDEX WHERE job_id='9745'
    log    ${queryResults[0][0]}
    ${last_query_index}=    Evaluate    ${queryResults[0][0]}+1
    log    ${last_query_index}
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    /bne-event-handler/bne/v1/jobs/9745/message-events    params=page_size=${PAGE_SIZE}    expected_status=Anything
    Status Should Be    200
    log    ${resp.json()}[fromIndex]
    Should Be Equal As Strings    ${resp.json()}[fromIndex]    ${last_query_index}
    ${queryResults}=    query    select LAST_QUERY_INDEX from QUERY_EVENT_INDEX WHERE job_id='202102'
    log    ${queryResults[0][0]}
    ${last_query_index}=    Evaluate    ${resp.json()}[fromIndex]+${resp.json()}[pageSize]-1
    Should Be Equal As Strings    ${queryResults[0][0]}    ${last_query_index}

Invalid multiple parameter value
    [Tags]    TC011
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=page_size=${PAGE_SIZE}&from_index=${FROM_INDEX}&event_id=${INVALID_VALUE}    expected_status=Anything
    Status Should Be    400
    Should Be Equal    ${resp.json()}[requestError][serviceException][exceptionMsgId]    SVC2000
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][0]    The requested query parameters are not valid. Please provide a valid Query parameters
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][1]    30001
    Should Be Equal    ${resp.json()}[requestError][serviceException][text] \    The following error occurred. %1. Error code is %2 \

Zero page size value
    [Tags]    TC012
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=page_size=${ZERO_VALUE}&from_index=${FROM_INDEX}    expected_status=Anything
    Status Should Be    400
    Should Be Equal    ${resp.json()}[requestError][serviceException][exceptionMsgId]    SVC2000
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][0]    The requested query parameters are not valid. Please provide a valid Query parameters
    Should Be Equal    ${resp.json()}[requestError][serviceException][variables][1]    30001
    Should Be Equal    ${resp.json()}[requestError][serviceException][text] \    The following error occurred. %1. Error code is %2 \

Form_Index value Out Of Range
    [Tags]    TC013
    ${queryResults}=    query    SELECT max(event_id) FROM message_event where job_id='${JOB_ID}'
    log    ${queryResults[0][0]}
    ${outofrangeValue}=    Evaluate    ${queryResults[0][0]}+10
    Create Session    httpbin    ${URL}
    ${resp}=    RequestsLibrary.Get On Session    httpbin    ${URI}    params=page_size=${PAGE_SIZE}&from_index=${outofrangeValue}    expected_status=Anything
    Status Should Be    204

*** Keywords ***
Open Server Connection and Log In
    ${index}=    Open Connection    ${EHTrafficNodeIP}    timeout=30s    prompt=${prompt}
    ${output}=    Run Keyword If    ${index} != 0    Login    ${Server_username}    ${Server_password}
    Should Contain    ${output}    ${Connected}
    Log to console    Connection to server is successful
