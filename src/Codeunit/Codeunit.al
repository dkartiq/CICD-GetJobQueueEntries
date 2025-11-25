codeunit 50000 "CICD-Get Job Queue Entries"
{
    trigger OnRun()
    begin

    end;

    [ServiceEnabled]
    procedure JobQueueJsonText(): Text
    var
        Comp: Record Company;
        JobQueueEntry: Record "Job Queue Entry";
        DataJson: JsonObject;
        JobQueueJson: JsonObject;
        JobQueueArray: JsonArray;
        Jsontext: Text;
    begin
        if Comp.FindSet() then
            repeat
                JobQueueEntry.ChangeCompany(Comp.Name);
                JobQueueEntry.SetCurrentKey("Object ID to Run");
                if JobQueueEntry.FindSet() then
                    repeat
                        Clear(JobQueueJson);
                        JobQueueJson.Add('id', JobQueueEntry.ID);
                        JobQueueJson.Add('companyName', Comp.Name);
                        // case JobQueueEntry."Object Type to Run" of
                        //     JobQueueEntry."Object Type to Run"::Codeunit:
                        //         JobQueueJson.Add('objectTypetoRun', 'Codeunit');
                        //     JobQueueEntry."Object Type to Run"::Report:
                        //         JobQueueJson.Add('objectTypetoRun', 'Report');
                        // end;
                        JobQueueJson.Add('objectTypetoRun', JobQueueEntry."Object Type to Run");
                        JobQueueJson.Add('objectIdtoRun', JobQueueEntry."Object ID to Run");
                        JobQueueJson.Add('originalStatus', JobQueueEntry.Status);
                        JobQueueArray.Add(JobQueueJson);
                    until JobQueueEntry.Next() = 0;
            until Comp.Next() = 0;
        DataJson.Add('data', JobQueueArray);
        DataJson.WriteTo(Jsontext);
        exit(Jsontext);
    end;

    [ServiceEnabled]
    procedure GetCurrentStatus(JsonText: Text): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
        CompName: Text;
        JobID: Guid;
        JsonObj, JsonObj2 : JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonItem: JsonObject;
        DataJson: JsonObject;
        JsonText1: Text;
    begin
        JsonObj.ReadFrom(JsonText);
        // Get the array "data"
        if JsonObj.Get('data', JsonToken) then begin
            JsonArray := JsonToken.AsArray();

            foreach JsonToken in JsonArray do begin
                JsonItem := JsonToken.AsObject();

                JsonItem.Get('id', JsonToken);
                JobID := JsonToken.AsValue().AsText();

                JsonItem.Get('companyName', JsonToken);
                CompName := JsonToken.AsValue().AsText();

                JobQueueEntry.ChangeCompany(CompName);
                if JobQueueEntry.Get() then begin
                    Clear(JsonObj2);
                    JsonObj2.Add('companyName', CompName);
                    JsonObj2.Add('id', JobQueueEntry.ID);
                    JsonObj2.Add('currentStatus', JobQueueEntry.Status);
                    JsonArray.Add(JsonObj2);
                end;
            end;
            DataJson.Add('data', JsonArray);
            DataJson.WriteTo(JsonText1);
            exit(JsonText1);
        end;
    end;

    [ServiceEnabled]
    procedure SetOriginalStatus(JsonText: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JsonObj, JsonObj2 : JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonItem: JsonObject;
        DataJson: JsonObject;
        CompName: Text;
        JobID: Guid;
        OriginalStatus: Integer;
        SessID: Integer;
    begin
        JsonObj.ReadFrom(JsonText);
        // Get the array "data"
        if JsonObj.Get('data', JsonToken) then begin
            JsonArray := JsonToken.AsArray();

            foreach JsonToken in JsonArray do begin
                JsonItem := JsonToken.AsObject();

                JsonItem.Get('id', JsonToken);
                JobID := JsonToken.AsValue().AsText();

                JsonItem.Get('companyName', JsonToken);
                CompName := JsonToken.AsValue().AsText();

                JsonItem.Get('orginalStatus', JsonToken);
                OriginalStatus := JsonToken.AsValue().AsInteger();

                JobQueueEntry.ChangeCompany(CompName);
                if JobQueueEntry.Get(JobID) then begin
                    JobQueueEntry.Status := OriginalStatus;
                    StartSession(SessID, Codeunit::"Job Queue Management", CompName, JobQueueEntry);
                end;
            end;
        end;
    end;
}