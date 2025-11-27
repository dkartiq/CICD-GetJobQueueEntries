codeunit 70005 "CICD-Get Job Queue Entries"
{
    Access = Public;
    trigger OnRun()
    begin

    end;

    [ServiceEnabled]
    procedure jobQueueJsonText(): Text
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
    procedure getCurrentStatus(id: Guid; companyName: Text): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
        JsonObj2: JsonObject;
        JsonArray: JsonArray;
        DataJson: JsonObject;
        JsonText1: Text;
    begin
        JobQueueEntry.ChangeCompany(companyName);
        if JobQueueEntry.Get(id) then begin
            Clear(JsonObj2);
            JsonObj2.Add('companyName', companyName);
            JsonObj2.Add('id', JobQueueEntry.ID);
            JsonObj2.Add('currentStatus', JobQueueEntry.Status);
            JsonArray.Add(JsonObj2);
        end;
        DataJson.Add('data', JsonArray);
        DataJson.WriteTo(JsonText1);
        exit(JsonText1);
    end;

    [ServiceEnabled]
    procedure setOriginalStatus(id: Guid; companyName: Text; orginalStatus: integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
        SessID: Integer;
    begin
        JobQueueEntry.ChangeCompany(companyName);
        if JobQueueEntry.Get(id) then begin
            JobQueueEntry.Status := orginalStatus;
            StartSession(SessID, Codeunit::"Job Queue Management", companyName, JobQueueEntry);
        end;
    end;
}