// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149046 "AIT Suite API"
{
    PageType = API;

    APIPublisher = 'microsoft';
    APIGroup = 'aiTestToolkit';
    APIVersion = 'v1.0';
    Caption = 'AIT Suite API';

    EntityCaption = 'AITSuite';
    EntitySetCaption = 'AITSuite';
    EntityName = 'aitSuite';
    EntitySetName = 'aitSuites';

    SourceTable = "AIT Header";
    ODataKeyFields = SystemId;

    Extensible = false;
    DelayedInsert = true;


    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field("code"; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(modelVersion; Rec.ModelVersion)
                {
                    Caption = 'Model Version';
                }
                field(dataset; Rec."Input Dataset")
                {
                    Caption = 'Dataset';
                }
                field(tag; Rec.Tag)
                {
                    Caption = 'Tag';
                }
                field("defaultMinimumUserDelayInMilliSeconds"; Rec."Default Min. User Delay (ms)")
                {
                    Caption = 'Default Min. User Delay (ms)';
                }
                field("defaultMaximumUserDelayInMilliSeconds"; Rec."Default Max. User Delay (ms)")
                {
                    Caption = 'Default Max. User Delay (ms)';
                }
                part("testSuitesLines"; "AIT Suite Line API")
                {
                    Caption = 'AIT Suite Line';
                    EntityName = 'aitSuiteLine';
                    EntitySetName = 'aitSuiteLines';
                    SubPageLink = "AIT Code" = field("Code");
                }
            }
        }
    }
}