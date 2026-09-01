trigger ContentDocumentLinkTrigger on ContentDocumentLink (After insert) {
    EventFormFileUpload.handleAfterInsert(Trigger.new);
}