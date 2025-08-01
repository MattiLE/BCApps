// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage;

using System;
using System.Utilities;
using System.Text;

codeunit 9044 "ABS Format Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure AppendToUri(var UriText: Text; ParameterIdentifier: Text; ParameterValue: Text)
    var
        Uri: Codeunit Uri;
        ConcatChar: Text;
        AppendType1Lbl: Label '%1%2=%3', Comment = '%1 = Concatenation character, %2 = Parameter Identifer, %3 = Parameter Value', Locked = true;
        AppendType2Lbl: Label '%1%2', Comment = '%1 = Concatenation character, %2 = Parameter Value', Locked = true;
        EscapedParameterValue: Text;
    begin
        ConcatChar := '?';
        if UriText.Contains('?') then
            ConcatChar := '&';
        EscapedParameterValue := Uri.EscapeDataString(ParameterValue);
        if ParameterIdentifier <> '' then
            UriText += StrSubstNo(AppendType1Lbl, ConcatChar, ParameterIdentifier, EscapedParameterValue)
        else
            UriText += StrSubstNo(AppendType2Lbl, ConcatChar, EscapedParameterValue)
    end;

    procedure RemoveCurlyBracketsFromString("Value": Text): Text
    begin
        exit(DelChr("Value", '=', '{}'));
    end;

    procedure GetBase64BlockId(): Text
    begin
        exit(GetBase64BlockId(RemoveCurlyBracketsFromString(Format(CreateGuid()))));
    end;

    procedure GetBase64BlockId(BlockId: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Uri: Codeunit Uri;
    begin
        exit(Uri.EscapeDataString(Base64Convert.ToBase64(BlockId)));
    end;

    procedure BlockDictionariesToBlockListDictionary(CommitedBlocks: Dictionary of [Text, Integer]; UncommitedBlocks: Dictionary of [Text, Integer]; var BlockList: Dictionary of [Text, Text]; OverwriteValueToLatest: Boolean)
    var
        Keys: List of [Text];
        "Key": Text;
        "Value": Text;
    begin
        "Value" := 'Committed';
        if OverwriteValueToLatest then
            "Value" := 'Latest';
        Keys := CommitedBlocks.Keys;
        foreach "Key" in Keys do
            BlockList.Add("Key", "Value");

        "Value" := 'Uncommitted';
        if OverwriteValueToLatest then
            "Value" := 'Latest';
        Keys := UncommitedBlocks.Keys;
        foreach "Key" in Keys do
            BlockList.Add("Key", "Value");
    end;

    procedure BlockListDictionaryToXmlDocument(BlockList: Dictionary of [Text, Text]): XmlDocument
    var
        Document: XmlDocument;
        BlockListNode: XmlNode;
        BlockNode: XmlNode;
        Keys: List of [Text];
        "Key": Text;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><BlockList></BlockList>', Document);
        Document.SelectSingleNode('/BlockList', BlockListNode);
        Keys := BlockList.Keys;
        foreach "Key" in Keys do begin
            BlockNode := XmlElement.Create(BlockList.Get("Key"), '', "Key").AsXmlNode(); // Dictionary value contains "Latest", "Committed" or "Uncommitted"
            BlockListNode.AsXmlElement().Add(BlockNode);
        end;
        exit(Document);
    end;

    procedure TagsDictionaryToXmlDocument(Tags: Dictionary of [Text, Text]): XmlDocument
    var
        Document: XmlDocument;
        TagSetNode: XmlNode;
        TagNode: XmlNode;
        KeyNode: XmlNode;
        ValueNode: XmlNode;
        Keys: List of [Text];
        "Key": Text;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><Tags><TagSet></TagSet></Tags>', Document);
        Document.SelectSingleNode('/Tags/TagSet', TagSetNode);
        Keys := Tags.Keys;
        foreach "Key" in Keys do begin
            TagNode := XmlElement.Create('Tag').AsXmlNode();
            KeyNode := XmlElement.Create('Key', '', "Key").AsXmlNode();
            ValueNode := XmlElement.Create('Value', '', Tags.Get("Key")).AsXmlNode();
            TagSetNode.AsXmlElement().Add(TagNode);

            TagNode.AsXmlElement().Add(KeyNode);
            TagNode.AsXmlElement().Add(ValueNode);
        end;
        exit(Document);
    end;

    procedure XmlDocumentToTagsDictionary(Document: XmlDocument): Dictionary of [Text, Text]
    var
        Tags: Dictionary of [Text, Text];
        TagNodesList: XmlNodeList;
        TagNode: XmlNode;
        KeyValue: Text;
        Value: Text;
    begin
        if not Document.SelectNodes('/Tags/TagSet/Tag', TagNodesList) then
            exit;

        foreach TagNode in TagNodesList do begin
            KeyValue := GetSingleNodeInnerText(TagNode, 'Key');
            Value := GetSingleNodeInnerText(TagNode, 'Value');
            if KeyValue = '' then begin
                Clear(Tags);
                exit;
            end;
            Tags.Add(KeyValue, Value);
        end;
        exit(Tags);
    end;

    local procedure GetSingleNodeInnerText(Node: XmlNode; XPath: Text): Text
    var
        ChildNode: XmlNode;
        XmlElement: XmlElement;
    begin
        if not Node.SelectSingleNode(XPath, ChildNode) then
            exit;
        XmlElement := ChildNode.AsXmlElement();
        exit(XmlElement.InnerText());
    end;

    procedure TagsDictionaryToSearchExpression(Tags: Dictionary of [Text, Text]): Text
    var
        Keys: List of [Text];
        "Key": Text;
        SingleQuoteChar: Char;
        Expression: Text;
        ExpressionPartLbl: Label '"%1" %2 %3%4%5', Comment = '%1 = Tag, %2 = Operator, %3 = Single Quote, %4 = Value, %5 = Single Quote', Locked = true;
    begin
        SingleQuoteChar := 39;
        Keys := Tags.Keys;
        foreach "Key" in Keys do begin
            if Expression <> '' then
                Expression += ' AND ';
            Expression += StrSubstNo(ExpressionPartLbl, "Key".Trim(), GetOperatorFromValue(Tags.Get("Key")).Trim(), SingleQuoteChar, GetValueWithoutOperator(Tags.Get("Key")).Trim(), SingleQuoteChar);
        end;
        exit(Expression);
    end;

    procedure QueryExpressionToQueryBlobContent(QueryExpression: Text): XmlDocument
    var
        Document: XmlDocument;
        QueryRequestNode: XmlNode;
        QueryTypeNode: XmlNode;
        ExpressionNode: XmlNode;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><QueryRequest></QueryRequest>', Document);
        Document.SelectSingleNode('/QueryRequest', QueryRequestNode);
        QueryTypeNode := XmlElement.Create('QueryType', '', 'SQL').AsXmlNode();
        QueryRequestNode.AsXmlElement().Add(QueryTypeNode);
        ExpressionNode := XmlElement.Create('Expression', '', QueryExpression).AsXmlNode();
        QueryRequestNode.AsXmlElement().Add(ExpressionNode);
        exit(Document);
    end;

    local procedure GetOperatorFromValue("Value": Text): Text
    var
        NewValue: Text;
    begin
        NewValue := "Value".Substring(1, "Value".IndexOf(' '));
        exit(NewValue.Trim());
    end;

    local procedure GetValueWithoutOperator("Value": Text): Text
    var
        NewValue: Text;
    begin
        NewValue := "Value".Substring("Value".IndexOf(' ') + 1);
        exit(NewValue.Trim());
    end;

    procedure TextToXmlDocument(SourceText: Text): XmlDocument
    var
        Document: XmlDocument;
    begin
        XmlDocument.ReadFrom(SourceText, Document);
        exit(Document);
    end;

    procedure ConvertToDateTime(PropertyValue: Text): DateTime
    var
        NewDateTime: DateTime;
    begin
        NewDateTime := 0DT;
        // PropertyValue is something like the following: 'Mon, 24 May 2021 12:25:27 GMT'
        // 'Evaluate' converts these correctly
        if Evaluate(NewDateTime, PropertyValue) then;
        exit(NewDateTime);
    end;

    procedure ConvertToInteger(PropertyValue: Text): Integer
    var
        NewInteger: Integer;
    begin
        if Evaluate(NewInteger, PropertyValue) then
            exit(NewInteger);
    end;

    procedure ConvertToBoolean(PropertyValue: Text): Boolean
    var
        NewBoolean: Boolean;
    begin
        if Evaluate(NewBoolean, PropertyValue) then
            exit(NewBoolean);
    end;

    procedure ConvertToEnum(FieldName: Text; PropertyValue: Text): Variant
    begin
        if FieldName = 'Resource Type' then
            case PropertyValue of
                Text.LowerCase(Format(Enum::"ABS Blob Resource Type"::File)):
                    exit(Enum::"ABS Blob Resource Type"::File);
                Text.LowerCase(Format(Enum::"ABS Blob Resource Type"::Directory)):
                    exit(Enum::"ABS Blob Resource Type"::Directory);
            end;
    end;

    procedure GetNewLineCharacter(): Text
    var
        LF: Char;
    begin
        LF := 10;
        exit(Format(LF));
    end;

    procedure GetIso8601DateTime(MyDateTime: DateTime): Text
    begin
        exit(FormatDateTime(MyDateTime, 's')); // https://go.microsoft.com/fwlink/?linkid=2210384
    end;

    procedure GetRfc1123DateTime(MyDateTime: DateTime): Text
    begin
        exit(FormatDateTime(MyDateTime, 'R')); // https://go.microsoft.com/fwlink/?linkid=2210384
    end;

    local procedure FormatDateTime(MyDateTime: DateTime; FormatSpecifier: Text): Text
    var
        DateTimeAsXmlString: Text;
        DateTimeDotNet: DotNet DateTime;
    begin
        DateTimeAsXmlString := Format(MyDateTime, 0, 9); // Format as XML, e.g.: 2020-11-11T08:50:07.553Z
        exit(DateTimeDotNet.Parse(DateTimeAsXmlString).ToUniversalTime().ToString(FormatSpecifier));
    end;
}
