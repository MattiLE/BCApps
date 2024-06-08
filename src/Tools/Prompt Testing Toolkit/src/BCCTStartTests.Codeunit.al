// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;

codeunit 149036 "BCCT Start Tests"
{
    TableNo = "BCCT Header";
    Access = Internal;

    trigger OnRun();
    begin
        this.StartAITests(Rec);
    end;

    var
        NothingToRunErr: Label 'There is nothing to run.';
        CannotRunMultipleSuitesInParallelErr: Label 'There is already test run in progress. Start this operaiton after that finishes.';
        RunningTestsMsg: Label 'Running tests...';

    local procedure StartAITests(BCCTHeader: Record "BCCT Header")
    var
        BCCTLine: Record "BCCT Line";
        BCCTHeaderCU: Codeunit "BCCT Header";
    begin
        this.ValidateLines(BCCTHeader);
        BCCTHeader.RunID := CreateGuid();
        BCCTHeader.Validate("Started at", CurrentDateTime);
        BCCTHeaderCU.SetRunStatus(BCCTHeader, BCCTHeader.Status::Running);

        BCCTHeader."No. of tests running" := 0;
        BCCTHeader.Version += 1;
        BCCTHeader.Modify();
        Commit();

        BCCTLine.SetRange("BCCT Code", BCCTHeader.Code);
        BCCTLine.SetFilter("Codeunit ID", '<>0');
        BCCTLine.SetRange("Version Filter", BCCTHeader.Version);
        if BCCTLine.FindSet() then begin
            BCCTLine.ModifyAll(Status, BCCTLine.Status::Running);
            Commit();
            Codeunit.Run(Codeunit::"AIT Test Runner", BCCTLine);
        end;
    end;

    internal procedure StartBCCTSuite(var BCCTHeader: Record "BCCT Header")
    var
        BCCTHeader2: Record "BCCT Header";
        StatusDialog: Dialog;
    begin
        // If there is already a suite running, then error
        BCCTHeader2.SetRange(Status, BCCTHeader2.Status::Running);
        if not BCCTHeader2.IsEmpty then
            Error(this.CannotRunMultipleSuitesInParallelErr);
        Commit();

        StatusDialog.Open(this.RunningTestsMsg);
        Codeunit.Run(Codeunit::"BCCT Start Tests", BCCTHeader);
        StatusDialog.Close();
        if BCCTHeader.Find() then;
    end;

    internal procedure StopBCCTSuite(var BCCTHeader: Record "BCCT Header")
    var
        BCCTHeaderCU: Codeunit "BCCT Header";
    begin
        BCCTHeaderCU.SetRunStatus(BCCTHeader, BCCTHeader.Status::Cancelled);
    end;

    internal procedure StartNextTestSuite(BCCTHeader: Record "BCCT Header")
    var
        BCCTHeader2: Record "BCCT Header";
        BCCTLine: Record "BCCT Line";
        BCCTHeaderCU: Codeunit "BCCT Header";
    begin
        BCCTHeader2.SetRange(Status, BCCTHeader2.Status::Running);
        BCCTHeader2.SetFilter(Code, '<> %1', BCCTHeader.Code);
        if not BCCTHeader2.IsEmpty() then
            Error(this.CannotRunMultipleSuitesInParallelErr);

        BCCTHeader.ReadIsolation(IsolationLevel::UpdLock);
        BCCTHeader.Find();
        if BCCTHeader.Status <> BCCTHeader.Status::Running then begin
            BCCTHeader.RunID := CreateGuid();
            BCCTHeader.Validate("Started at", CurrentDateTime);
            BCCTHeaderCU.SetRunStatus(BCCTHeader, BCCTHeader.Status::Running);

            BCCTHeader."No. of tests running" := 0;
            BCCTHeader.Version += 1;
            BCCTHeader."No. of tests running" := 0;
            BCCTHeader.Modify();

            BCCTLine.SetRange("BCCT Code", BCCTHeader.Code);
            if BCCTLine.FindSet(true) then
                repeat
                    BCCTLine.Status := BCCTLine.Status::" ";
                    BCCTLine."Total Duration (ms)" := 0;
                    BCCTLine."No. of Tests" := 0;
                    BCCTLine.SetRange("Version Filter", BCCTHeader.Version);
                    BCCTLine.Modify(true);
                until BCCTLine.Next() = 0;
        end;

        BCCTLine.ReadIsolation(IsolationLevel::UpdLock);
        BCCTLine.SetRange("BCCT Code", BCCTHeader.Code);
        BCCTLine.SetFilter("Codeunit ID", '<>0');
        BCCTLine.SetFilter(Status, '%1 | %2', BCCTLine.Status::" ", BCCTLine.Status::Starting);
        if BCCTLine.FindFirst() then begin
            BCCTHeader."No. of tests running" += 1;
            BCCTLine.Status := BCCTLine.Status::Running;
            BCCTHeader.Modify();
            BCCTLine.Modify();
            Commit();
            BCCTLine.SetRange("Line No.", BCCTLine."Line No.");
            BCCTLine.SetRange(Status);
            Codeunit.Run(Codeunit::"AIT Test Runner", BCCTLine);
        end else
            Error(this.NothingToRunErr);
    end;

    local procedure ValidateLines(BCCTHeader: Record "BCCT Header")
    var
        BCCTLine: Record "BCCT Line";
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        BCCTLine.SetRange("BCCT Code", BCCTHeader.Code);

        if not BCCTLine.FindSet() then
            Error('There is nothing to run.');

        repeat
            CodeunitMetadata.Get(BCCTLine."Codeunit ID");
        until BCCTLine.Next() = 0;
    end;
}