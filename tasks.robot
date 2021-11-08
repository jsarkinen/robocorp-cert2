# +
*** Settings ***
Documentation   This robot is created for Certification level 2 work
...             Robot orders robots from web site
...             Stores order receipts to PDF files
...             Collects screenshots from robot images
...             Adds the screenshot to the PDF receipt
...             Adds all PDF files to a ZIP archive

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           OperatingSystem
Library           RPA.Archive
Library           DateTime
Library           RPA.Dialogs
Library           Collections
Library           RPA.Robocorp.Vault
# -


*** Keywords ***
Open the robot order website
    ${store}=    Get Secret    store
    Open Available Browser    ${store}[store_url]

*** Keywords ***
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    ${CURDIR}${/}orders.csv
    [Return]    ${table}

*** Keywords ***
Get user name
    Add text input    user_name    label=Please type your name
    ${response}=    Run dialog
    [Return]    ${response.user_name}

*** Keywords ***
Fill the form
    [Arguments]    ${order_row}
    #Log    ${order_row}[Address]
    Select From List By Value    head    ${order_row}[Head]
    Select Radio Button    body    ${order_row}[Body]
    Input Text    xpath: //input[@type='number']    ${order_row}[Legs]
    Input Text    id:address    ${order_row}[Address]
    Click Button    id:preview
    Wait Until Keyword Succeeds    5x    0.5s    Click order button


*** Keywords ***
Click order button
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}${order_number}.pdf

*** Keywords ***
Take a screenshot of the robot and add to PDF
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${order_number}.png
    [Return]    ${CURDIR}${/}output${/}${order_number}.png

*** Keywords ***
Close the popup
    Click Button    class:btn-warning

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order_number}   ${screenshot_path}    ${pdf_path}
    ${files}=    Create List
    ...    ${pdf_path}
    ...    ${screenshot_path}
    Add Files To Pdf    ${files}    ${CURDIR}${/}output${/}${order_number}_receipt.pdf
    Remove File    ${pdf_path}    
    Remove File    ${screenshot_path}

*** Keywords ***
Create a ZIP archive from output dir
    [Arguments]    ${user_name}
    ${date} =    Get Current Date
    Archive Folder With ZIP    ${CURDIR}${/}output${/}    ${CURDIR}${/}output${/}${user_name}_${date}.zip

*** Keywords ***
Clean output dir
    Remove File    ${CURDIR}${/}output${/}*.pdf

# +
*** Tasks ***
Orders robots from web site
    Open the robot order website
    ${name}=    Get user name
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the popup
        Fill the form    ${order}
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot and add to PDF    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${order}[Order number]    ${screenshot}    ${pdf}
        Click Button    id:order-another
    END
    Create a ZIP archive from output dir    ${name}
    Clean output dir
    
    
