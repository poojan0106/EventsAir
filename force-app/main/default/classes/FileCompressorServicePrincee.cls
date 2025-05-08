public class FileCompressorServicePrincee {
    
    List<Id> contentDocumentIds=new List<Id>();
    Compression.ZipWriter writer;
    
    private Compression.ZipWriter getCreateZipWriter()
    {
        if(writer==null)
        {
            writer = new Compression.ZipWriter();
        }
        return writer;
    }
    
    //Compress Single File
    public FileCompressorServicePrincee(Id fileId)
    {
        contentDocumentIds.add(fileId);
    }

    //Compress Multiple Files
    public FileCompressorServicePrincee(List<Id> fileIds)
    {
        contentDocumentIds.addAll(fileIds);
    }
    
    //Compress Blob Data
    public void addFile(string fileName, blob data)
    {
        getCreateZipWriter();
        writer.addEntry(fileName,data);
    }
    
    //Add file data to ZipWriter
    private void addContentFiles()
    {
        if(!contentDocumentIds.isEmpty())
        {
            // Add IDs of documents to be compressed to contentDocumentIds 
            for ( ContentVersion cv : [SELECT PathOnClient, Versiondata
                                       FROM ContentVersion
                                       WHERE Id IN :contentDocumentIds]) 
            {
                writer.addEntry(cv.PathOnClient, cv.versiondata);
            }
        }
    }
    
    public blob compressFiles()
    {
        getCreateZipWriter();
        addContentFiles();
        return writer.getArchive();
    }

}