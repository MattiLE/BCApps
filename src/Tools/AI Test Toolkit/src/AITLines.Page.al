// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149034 "AIT Lines"
{
    Caption = 'Tests';
    PageType = ListPart;
    SourceTable = "AIT Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("LoadTestCode"; Rec."AIT Code")
                {
                    ToolTip = 'Specifies the ID of the AIT.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field(LineNo; Rec."Line No.")
                {
                    ToolTip = 'Specifies the line number of the AIT line.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field(CodeunitID; Rec."Codeunit ID")
                {
                    ToolTip = 'Specifies the codeunit id to run.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                    ToolTip = 'Specifies the name of the codeunit.';
                    ApplicationArea = All;
                }
                field(InputDataset; Rec."Input Dataset")
                {
                    ToolTip = 'Specifies a dataset that overrides the default dataset for the suite.';
                    ApplicationArea = All;
                }
                field("Delay (ms btwn. iter.)"; Rec."Delay (ms btwn. iter.)")
                {
                    ToolTip = 'Specifies the delay between iterations.';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the AIT line.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the status of the AIT.';
                    ApplicationArea = All;
                }
                field(MinDelay; Rec."Min. User Delay (ms)")
                {
                    ToolTip = 'Specifies the min. user delay in ms of the AIT.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(MaxDelay; Rec."Max. User Delay (ms)")
                {
                    ToolTip = 'Specifies the max. user delay in ms of the AIT.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Tests"; Rec."No. of Tests")
                {
                    Tooltip = 'Specifies the number of tests in this Line';
                    ApplicationArea = All;
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    ToolTip = 'Specifies the number of tests passed in the current Version.';
                }
                field("No. of Tests Failed"; Rec."No. of Tests" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'No. of Tests Failed';
                    ToolTip = 'Specifies the number of tests that failed in the current Version.';
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    var
                        AITHeaderRec: Record "AIT Header";
                    begin
                        AITHeaderRec.SetLoadFields(Version); // TODO: See if  there is a better way to do this
                        AITHeaderRec.Get(Rec."AIT Code");
                        FailedTestsAITLogEntryDrillDown(AITHeaderRec.Version);
                    end;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of operations in the current Version.';
                }
                field(Duration; Rec."Total Duration (ms)")
                {
                    ToolTip = 'Specifies Total Duration of the AIT for this role.';
                    ApplicationArea = All;
                }
                field(AvgDuration; AITLineCU.GetAvgDuration(Rec))
                {
                    ToolTip = 'Specifies average duration of the AIT for this role.';
                    Caption = 'Average Duration (ms)';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Tests - Base"; Rec."No. of Tests - Base")
                {
                    Tooltip = 'Specifies the number of tests in this Line for the base version.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of tests passed in the base Version.';
                    Style = Favorable;
                    Visible = false;
                }
                field("No. of Tests Failed - Base"; Rec."No. of Tests - Base" - Rec."No. of Tests Passed - Base")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'No. of Tests Failed - Base';
                    ToolTip = 'Specifies the number of tests that failed in the base Version.';
                    Style = Unfavorable;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        AITHeaderRec: Record "AIT Header";
                    begin
                        AITHeaderRec.SetLoadFields("Base Version"); // TODO: See if  there is a better way to do this
                        AITHeaderRec.Get(Rec."AIT Code");
                        FailedTestsAITLogEntryDrillDown(AITHeaderRec."Base Version");
                    end;
                }
                field("No. of Operations - Base"; Rec."No. of Operations - Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of operations in the base Version.';
                    Visible = false;
                }
                field(DurationBase; Rec."Total Duration - Base (ms)")
                {
                    ToolTip = 'Specifies Total Duration of the AIT for this role for the base version.';
                    Caption = 'Total Duration Base (ms)';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(AvgDurationBase; GetAvg(Rec."No. of Tests - Base", Rec."Total Duration - Base (ms)"))
                {
                    ToolTip = 'Specifies average duration of the AIT for this role for the base version.';
                    Caption = 'Average Duration Base (ms)';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(AvgDurationDeltaPct; GetDiffPct(GetAvg(Rec."No. of Tests - Base", Rec."Total Duration - Base (ms)"), GetAvg(Rec."No. of Tests", Rec."Total Duration (ms)")))
                {
                    ToolTip = 'Specifies difference in duration of the AIT for this role compared to the base version.';
                    Caption = 'Change in Duration (%)';
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Start)
            {
                ApplicationArea = All;
                Caption = 'Run';
                Image = Start;
                Tooltip = 'Starts running the AIT Line.';

                trigger OnAction()
                begin
                    AITHeader.Get(Rec."AIT Code");
                    AITHeader.Version += 1;
                    AITHeader.Modify();
                    Commit();
                    // If no range is set, all following foreground lines will be run
                    Rec.SetRange("Codeunit ID", Rec."Codeunit ID");
                    Codeunit.Run(codeunit::"AIT Test Runner", Rec);
                    Rec.SetRange("Codeunit ID"); // reset filter
                end;
            }
            action(Indent)
            {
                ApplicationArea = All;
                Visible = false;
                Caption = 'Make Child';  //'Indent';
                Image = Indent;
                ToolTip = 'Make this process a child of the above session.';
                trigger OnAction()
                begin
                    AITLineCU.Indent(Rec);
                end;
            }
            action(Outdent)
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
                Caption = 'Make Session';  //'Outdent';
                Image = DecreaseIndent;
                ToolTip = 'Make this process its own session.';

                trigger OnAction()
                begin
                    AITLineCU.Outdent(Rec);
                end;
            }
            action(LogEntries)
            {
                ApplicationArea = All;
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries for the line.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "AIT Code" = field("AIT Code"), "AIT Line No." = field("Line No."), Version = field("Version Filter");
            }
            action(Compare)
            {
                ApplicationArea = All;
                Caption = 'Compare Versions';
                Image = CompareCOA;
                ToolTip = 'Compare results of the line to a base version.';
                Scope = Repeater;

                trigger OnAction()
                var
                    AITLine: Record "AIT Line";
                    AITHeaderRec: Record "AIT Header";
                    AITLineComparePage: Page "AIT Lines Compare";
                begin
                    CurrPage.SetSelectionFilter(AITLine);

                    if not AITLine.FindFirst() then
                        Error(NoLineSelectedErr);

                    AITHeaderRec.SetLoadFields(Version, "Base Version");
                    AITHeaderRec.Get(Rec."AIT Code");

                    AITLineComparePage.SetBaseVersion(AITHeaderRec."Base Version");
                    AITLineComparePage.SetVersion(AITHeaderRec.Version);
                    AITLineComparePage.SetRecord(AITLine);
                    AITLineComparePage.Run();
                end;
            }
        }
    }
    var
        AITHeader: Record "AIT Header";
        AITLineCU: Codeunit "AIT Line";
        NoLineSelectedErr: Label 'Select a line to compare';

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Min. User Delay (ms)" := AITHeader."Default Min. User Delay (ms)";
        Rec."Max. User Delay (ms)" := AITHeader."Default Max. User Delay (ms)";
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."AIT Code" = '' then
            exit(true);
        if Rec."AIT Code" <> AITHeader.Code then
            if AITHeader.Get(Rec."AIT Code") then;
    end;

    local procedure GetAvg(NumIterations: Integer; TotalNo: Integer): Integer
    begin
        if NumIterations = 0 then
            exit(0);
        exit(TotalNo div NumIterations);
    end;

    local procedure GetDiffPct(BaseNo: Integer; No: Integer): Decimal
    begin
        if BaseNo = 0 then
            exit(0);
        exit(round((100 * (No - BaseNo)) / BaseNo, 0.1));
    end;

    internal procedure Refresh()
    begin
        CurrPage.Update(false);
        if Rec.Find() then;
    end;

    local procedure FailedTestsAITLogEntryDrillDown(VersionNo: Integer)
    var
        AITLogEntries: Record "AIT Log Entry";
        AITLogEntry: Page "AIT Log Entries";
    begin
        AITLogEntries.SetFilterForFailedTestProcedures();
        AITLogEntries.SetRange("AIT Code", Rec."AIT Code");
        AITLogEntries.SetRange(Version, VersionNo);
        AITLogEntries.SetRange("AIT Line No.", Rec."Line No.");
        AITLogEntry.SetTableView(AITLogEntries);
        AITLogEntry.Run();
    end;
}