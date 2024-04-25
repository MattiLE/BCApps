// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Reflection;

codeunit 149036 "BCCT Start Tests"
{
    TableNo = "BCCT Header";
    Access = Internal;

    trigger OnRun();
    begin
        StartBenchmarkTests(Rec);
    end;

    var
        NothingToRunErr: Label 'There is nothing to run.';
        CannotRunMultipleSuitesInParallelErr: Label 'There is already test run in progress. Start this operaiton after that finishes.';

    local procedure StartBenchmarkTests(BCCTHeader: Record "BCCT Header")
    var
        BCCTLine: Record "BCCT Line";
        BCCTHeaderCU: Codeunit "BCCT Header";
        s: Integer;
    begin
        ValidateLines(BCCTHeader);
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
        BCCTLine.SetRange("Run in Foreground", false);
        BCCTLine.Locktable();
        if BCCTLine.FindSet() then
            repeat

                StartSession(s, Codeunit::"BCCT Role Wrapper", CompanyName, BCCTLine);
                BCCTHeader."No. of tests running" += 1;

                BCCTLine.Status := BCCTLine.Status::Running;
                BCCTLine.Modify();
            until BCCTLine.Next() = 0;
        BCCTHeader.Modify();
        Commit();
        BCCTLine.SetRange("Run in Foreground", true);
        if BCCTLine.FindSet() then begin
            BCCTLine.ModifyAll(Status, BCCTLine.Status::Running);
            Commit();
            Codeunit.Run(Codeunit::"BCCT Role Wrapper", BCCTLine);
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
            Error(CannotRunMultipleSuitesInParallelErr);
        Commit();

        StatusDialog.Open('Starting background tasks and running any foreground tasks...');
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

    internal procedure StartNextBenchmarkTests(BCCTHeader: Record "BCCT Header")
    var
        BCCTHeader2: Record "BCCT Header";
        BCCTLine: Record "BCCT Line";
        BCCTHeaderCU: Codeunit "BCCT Header";
    begin
        BCCTHeader2.SetRange(Status, BCCTHeader2.Status::Running);
        BCCTHeader2.SetFilter(Code, '<> %1', BCCTHeader.Code);
        if not BCCTHeader2.IsEmpty() then
            Error(CannotRunMultipleSuitesInParallelErr);

        BCCTHeader.LockTable();
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
                    BCCTLine."No. of Iterations" := 0;
                    // BCCTLine."No. of Running Sessions" := 0;
                    // BCCTLine."No. of SQL Statements" := 0;
                    BCCTLine.SetRange("Version Filter", BCCTHeader.Version);
                    BCCTLine.Modify(true);
                until BCCTLine.Next() = 0;
        end;

        BCCTLine.LockTable();
        BCCTLine.SetRange("BCCT Code", BCCTHeader.Code);
        BCCTLine.SetFilter("Codeunit ID", '<>0');
        BCCTLine.SetFilter(Status, '%1 | %2', BCCTLine.Status::" ", BCCTLine.Status::Starting);
        if BCCTLine.FindFirst() then begin
            // if BCCTLine."No. of Running Sessions" < BCCTLine."No. of Sessions" then begin
            //     BCCTHeader."No. of tests running" += 1;
            //     BCCTLine."No. of Running Sessions" += 1;

            // if BCCTLine."No. of Running Sessions" < BCCTLine."No. of Sessions" then begin
            //     if BCCTHeader.CurrentRunType = BCCTHeader.CurrentRunType::PRT then
            //         BCCTLine.Status := BCCTLine.Status::Running
            //     else
            //         BCCTLine.Status := BCCTLine.Status::Starting;
            // end else
            //     BCCTLine.Status := BCCTLine.Status::Running;
            BCCTHeader.Modify();
            BCCTLine.Modify();
            Commit();
            BCCTLine.SetRange("Line No.", BCCTLine."Line No.");
            BCCTLine.SetRange(Status);
            Codeunit.Run(Codeunit::"BCCT Role Wrapper", BCCTLine);

            BCCTLine.LockTable();
            // if BCCTLine.Get(BCCTLine."BCCT Code", BCCTLine."Line No.") then
            //     if BCCTLine."No. of Running Sessions" = BCCTLine."No. of Sessions" then begin
            //         BCCTLine.Status := BCCTLine.Status::Completed;
            //         BCCTLine.Modify();
            //     end;
            //end;
            Commit();
        end else
            Error(NothingToRunErr);
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