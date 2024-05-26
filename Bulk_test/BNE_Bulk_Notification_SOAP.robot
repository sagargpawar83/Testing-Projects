*** Settings ***
Suite Setup       Run keywords    Connect To Database    ${DB}    ${DBName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}
...               AND    Open Server Connection and Log In
Suite Teardown    Run Keywords    Close All Connections
...               AND    Disconnect From Database
Library           requests
Library           Collections
Library           String
Library           XML
Library           RequestsLibrary
Library           SoapLibrary
Library           SSHLibrary
Library           OperatingSystem
Library           JSONLibrary
Library           DatabaseLibrary
Library           OperatingSystem
Library           Process
Library           DateTime
Library           ../Resources/Tx_log_util.py
Resource          ../Resources/bne_regression_variable.txt

*** Test Cases ***
Scheduled single SOAP message
    [Tags]    TC001
    ${timestamp}=    Get Current Date    result_format=%Y%m%d-%H%M%S
    ${TAG_uniqueid}    Generate Random String    length=5
    ${TAG_uniqueid}    Set Variable    ${TAG_uniqueid}-${timestamp}
    create session    send_soap    ${soap_url}    disable_warnings=1
    ${SOAP_XML}=    set variable    <?xml version="1.0" encoding="UTF-8"?> <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.bulknotification.bne.sdg.ericsson.com/"><soapenv:Header/><soapenv:Body><ser:addSubscriberJobItems><format>invoke</format><password>${password}</password><!--1 or more repetitions:--><textdata>${msisdn},${Sch_jobid},en,,,${TAG_uniqueid}${MSG_TXT}</textdata><userName>${username}</userName></ser:addSubscriberJobItems></soapenv:Body></soapenv:Envelope>
    ${request_header}=    create dictionary    Content-Type=text/xml; charset=utf-8
    ${response}=    RequestsLibrary.Post Request    send_soap    ${soap_endpoint_url}    headers=${request_header}    data=${SOAP_XML}
    Log    ${response.status_code}
    ${statusCode}    Set Variable    ${response.status_code}
    ${var}    Convert To Integer    ${statusCode}
    Should Be Equal As Strings    ${var}    200
    Sleep    10s
    ##### DB Validation #####
    ${NM_Data}=    Query    select MESSAGE_ID,MSISDN,TAG_FIELDS,MESSAGE_TEXT,delivery_status,notification_source from ${NMtable} where JOB_ID='${Sch_jobid}' and TAG_FIELDS like '["${TAG_uniqueid}${MSG_TXT}"%]'
    Log To Console    ${NM_Data}
    ${MESSAGE_ID}=    Get From List    ${NM_Data[0]}    0
    ${MESSAGE_ID}    Set Variable    ${MESSAGE_ID}
    ${TAG_FIELDS}=    Get From List    ${NM_Data[0]}    2
    Log    ${TAG_FIELDS}
    Log To Console    Message successfully onboarded in NM Table
    ${PSM_Data}=    Query    select delivery_status from ${PSM_table} where message_id='${MESSAGE_ID}'
    Log    ${PSM_Data}
    Log To Console    Message successfully onboarded in PSM Table
    Sleep    20s
    ##Log Validation##
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check1}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}    ${log_name_Bulk}    ${pod_folder}    ${MESSAGE_ID}
    Should Contain Match    ${log_check1}    *${MESSAGE_ID}*
    Should Not Contain Match    ${log_check1}    *FAILED*
    Log To Console    ${log_check1}
    Sleep    20s
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Sch}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check2}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Sch}    ${log_name_Sch}    ${pod_folder}    ${MESSAGE_ID}
    Log To Console    ${log_check2}
    Should Contain Match    ${log_check2}    *${MESSAGE_ID}*
    Should Not Contain Match    ${log_check2}    *FAILED*

Scheduled Bulk SOAP message
    [Tags]    TC002
    ${timestamp}=    Get Current Date    result_format=%Y%m%d-%H%M%S
    ${TAG_uniqueid}    Generate Random String    length=5
    ${TAG_uniqueid}    Set Variable    ${TAG_uniqueid}-${timestamp}
    create session    send_soap    ${soap_url}    disable_warnings=1
    ${SOAP_XML}=    set variable    <?xml version="1.0" encoding="UTF-8"?> <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.bulknotification.bne.sdg.ericsson.com/"><soapenv:Header/><soapenv:Body><ser:addSubscriberJobItems><format>invoke</format><password>${password}</password><!--1 or more repetitions:--><textdata>${msisdn},${Sch_jobid},en,,,${TAG_uniqueid}${MSG_TXT}</textdata><textdata>${msisdn},${Sch_jobid},en,,,${TAG_uniqueid}${MSG_TXT}</textdata><userName>${username}</userName></ser:addSubscriberJobItems></soapenv:Body></soapenv:Envelope>
    ${request_header}=    create dictionary    Content-Type=text/xml; charset=utf-8
    ${response}=    RequestsLibrary.Post Request    send_soap    ${soap_endpoint_url}    headers=${request_header}    data=${SOAP_XML}
    Log    ${response.status_code}
    ${statusCode}    Set Variable    ${response.status_code}
    ${var}    Convert To Integer    ${statusCode}
    Should Be Equal As Strings    ${var}    200
    Sleep    10s
    ##### DB Validation #####
    ${NM_Data}=    Query    select MESSAGE_ID,MSISDN,TAG_FIELDS,MESSAGE_TEXT,delivery_status,notification_source from ${NMtable} where JOB_ID='${Sch_jobid}' and TAG_FIELDS like '["${TAG_uniqueid}${MSG_TXT}"%]'
    Log To Console    ${NM_Data}
    ${MESSAGE_ID}=    Get From List    ${NM_Data[0]}    0
    ${MESSAGE_ID}    Set Variable    ${MESSAGE_ID}
    ${TAG_FIELDS}=    Get From List    ${NM_Data[0]}    2
    Log    ${TAG_FIELDS}
    Log To Console    Message successfully onboarded in NM Table
    ${PSM_Data}=    Query    select delivery_status from ${PSM_table} where message_id='${MESSAGE_ID}'
    Log    ${PSM_Data}
    Log To Console    Message successfully onboarded in PSM Table
    Sleep    20s
    ##Log Validation##
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check1}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}    ${log_name_Bulk}    ${pod_folder}    ${MESSAGE_ID}
    Log To Console    ${log_check1}
    Should Contain Match    ${log_check1}    *${MESSAGE_ID}*
    Should Not Contain Match    ${log_check1}    *FAILED*
    Sleep    20s
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Sch}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check2}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Sch}    ${log_name_Sch}    ${pod_folder}    ${MESSAGE_ID}
    Log To Console    ${log_check2}
    ${log_list2}=    Split String    ${log_check2}[1]    separator=,
    Log    ${log_list2}
    Should Be Equal As Strings    ${log_list2[12]}    ${MESSAGE_ID}
    Should Not Contain Match    ${log_check2}    *FAILED*

Immediate single SOAP message
    [Tags]    TC003
    ${timestamp}=    Get Current Date    result_format=%Y%m%d-%H%M%S
    ${TAG_uniqueid}    Generate Random String    length=5
    ${TAG_uniqueid}    Set Variable    ${TAG_uniqueid}-${timestamp}
    create session    send_soap    ${soap_url}    disable_warnings=1
    ${SOAP_XML}=    set variable    <?xml version="1.0" encoding="UTF-8"?> <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.bulknotification.bne.sdg.ericsson.com/"><soapenv:Header/><soapenv:Body><ser:addSubscriberJobItems><format>invoke</format><password>${password}</password><!--1 or more repetitions:--><textdata>${msisdn},${Imm_jobid},en,,,${TAG_uniqueid}${MSG_TXT}</textdata><userName>${username}</userName></ser:addSubscriberJobItems></soapenv:Body></soapenv:Envelope>
    ${request_header}=    create dictionary    Content-Type=text/xml; charset=utf-8
    ${response}=    RequestsLibrary.Post Request    send_soap    ${soap_endpoint_url}    headers=${request_header}    data=${SOAP_XML}
    Log    ${response.status_code}
    ${statusCode}    Set Variable    ${response.status_code}
    ${var}    Convert To Integer    ${statusCode}
    Should Be Equal As Strings    ${var}    200
    Sleep    10s
    ##### DB Validation #####
    ${NM_Data}=    Query    select MESSAGE_ID,MSISDN,TAG_FIELDS,MESSAGE_TEXT,delivery_status,notification_source from ${NMtable} where JOB_ID='${Imm_jobid}' and TAG_FIELDS like '["${TAG_uniqueid}${MSG_TXT}"%]'
    Log To Console    ${NM_Data}
    ${MESSAGE_ID}=    Get From List    ${NM_Data[0]}    0
    ${MESSAGE_ID}    Set Variable    ${MESSAGE_ID}
    ${TAG_FIELDS}=    Get From List    ${NM_Data[0]}    2
    Log    ${TAG_FIELDS}
    Log To Console    Message successfully onboarded in NM Table
    ${PIM_Data}=    Query    select delivery_status from ${PIM_table} where message_id='${MESSAGE_ID}'
    Log    ${PIM_Data}
    Log To Console    Message successfully onboarded in PIM Table
    Sleep    20s
    ##Log Validation##
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check1}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}    ${log_name_Bulk}    ${pod_folder}    ${MESSAGE_ID}
    Log To Console    ${log_check1}
    Should Contain Match    ${log_check1}    *${MESSAGE_ID}*
    Sleep    20s
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Imm}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check2}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Imm}    ${log_name_Imm}    ${pod_folder}    ${MESSAGE_ID}
    Log To Console    ${log_check2}
    Should Contain Match    ${log_check2}    *${MESSAGE_ID}*

Immediate Bulk SOAP message
    [Tags]    TC004
    ${timestamp}=    Get Current Date    result_format=%Y%m%d-%H%M%S
    ${TAG_uniqueid}    Generate Random String    length=5
    ${TAG_uniqueid}    Set Variable    ${TAG_uniqueid}-${timestamp}
    create session    send_soap    ${soap_url}    disable_warnings=1
    ${SOAP_XML}=    set variable    <?xml version="1.0" encoding="UTF-8"?> <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.bulknotification.bne.sdg.ericsson.com/"><soapenv:Header/><soapenv:Body><ser:addSubscriberJobItems><format>invoke</format><password>${password}</password><!--1 or more repetitions:--><textdata>${msisdn},${Imm_jobid},en,,,${TAG_uniqueid}${MSG_TXT}</textdata><textdata>${msisdn},${Imm_jobid},en,,,${TAG_uniqueid}${MSG_TXT}</textdata><userName>${username}</userName></ser:addSubscriberJobItems></soapenv:Body></soapenv:Envelope>
    ${request_header}=    create dictionary    Content-Type=text/xml; charset=utf-8
    ${response}=    RequestsLibrary.Post Request    send_soap    ${soap_endpoint_url}    headers=${request_header}    data=${SOAP_XML}
    Log    ${response.status_code}
    ${statusCode}    Set Variable    ${response.status_code}
    ${var}    Convert To Integer    ${statusCode}
    Should Be Equal As Strings    ${var}    200
    Sleep    10s
    ##### DB Validation #####
    ${NM_Data}=    Query    select MESSAGE_ID,MSISDN,TAG_FIELDS,MESSAGE_TEXT,delivery_status,notification_source from ${NMtable} where JOB_ID='${Imm_jobid}' and TAG_FIELDS like '["${TAG_uniqueid}${MSG_TXT}"%]'
    Log To Console    ${NM_Data}
    ${MESSAGE_ID}=    Get From List    ${NM_Data[0]}    0
    ${MESSAGE_ID}    Set Variable    ${MESSAGE_ID}
    ${TAG_FIELDS}=    Get From List    ${NM_Data[0]}    2
    Log    ${TAG_FIELDS}
    Log To Console    Message successfully onboarded in NM Table
    ${PIM_Data}=    Query    select delivery_status from ${PIM_table} where message_id='${MESSAGE_ID}'
    Log    ${PIM_Data}
    Log To Console    Message successfully onboarded in PIM Table
    Sleep    20s
    ##Log Validation##
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check1}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Bulk}    ${log_name_Bulk}    ${pod_folder}    ${MESSAGE_ID}
    Log To Console    ${log_check1}
    Should Contain Match    ${log_check1}    *${MESSAGE_ID}*
    Sleep    20s
    ${get_folder_name}    Tx_log_util.get_folder_name    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Imm}
    Log    ${get_folder_name}
    ${folder_name}    Remove String    ${get_folder_name}    \n
    ${pod_folder}    Set Variable    ${folder_name}
    Log    ${pod_folder}
    ${log_check2}    Tx_log_util.onboarding_log_check    ${BNE_MONITORING_NODE_IPAddress}    ${BNE_MONITORING_NODE_USERNAME}    ${BNE_MONITORING_NODE_PASSWORD}    ${log_path_Imm}    ${log_name_Imm}    ${pod_folder}    ${MESSAGE_ID}
    Log To Console    ${log_check2}
    ${log_list2}=    Split String    ${log_check2}[1]    separator=,
    Log    ${log_list2}
    Should Be Equal As Strings    ${log_list2[12]}    ${MESSAGE_ID}

*** Keywords ***
Open Server Connection and Log In
    ${index}=    Open Connection    ${traffic1_serverIP}    alias=traffic1    timeout=30s    prompt=${prompt}
    ${output}=    Run Keyword If    ${index} != 0    Login    ${Server_username}    ${Server_password}
    Log to console    Connection to server is successful
