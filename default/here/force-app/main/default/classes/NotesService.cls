/**
 * Created by marcelo.cost on 11/2/21.
 */

public with sharing class NotesService {

    public static ContentVersion  generateNoteforObjectId(Id parentId, String body, String title){
        ContentVersion objCntNote = new ContentVersion();
        objCntNote.Title = title;
        objCntNote.PathOnClient = objCntNote.Title + '.snote';
        objCntNote.VersionData = Blob.valueOf(body);
        objCntNote.FirstPublishLocationId = parentId;  // ParentId
        return objCntNote;
    }
}