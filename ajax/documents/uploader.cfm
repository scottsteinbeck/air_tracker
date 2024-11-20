<cfscript>
    // dump(listToArray(form.fieldnames)); abort;
    formFiles = listToArray(form.fieldnames);

    for(i=1; i < formFiles.len()+1; i++){
        path = "../../user_files/#url.dID#";

        if(left(formFiles[i], 4) != "file") continue;

        if(!directoryExists(expandPath(path))) directoryCreate(path);

        uploadedFile = fileUpload(expandPath(path), "form.#formFiles[i]#", " ", "makeunique");
        cleanedFileName = rereplace(uploadedFile.clientfilename,"[^0-9A-Za-z-]","_","All");

        cleanedFileName = getUniqueFileName(
                uploadedFile.serverdirectory,
                cleanedFileName,
                uploadedFile.clientfileext,
                0
            );

        fileMove(
            "#expandPath(path)#/#uploadedFile.serverfile#",
            "#expandPath(path)#/#cleanedFileName#"
        );
    }

    function getUniqueFileName(filePath, file, ext, uniqueid=0){
        var attemptedFilename = "#file##((uniqueid > 0) ? uniqueid : '')#.#ext#";
        
        if(fileExists(filePath & "/" & attemptedFilename)){
            uniqueid++;
            return getUniqueFileName(filePath, file, ext, uniqueid);
        }
        return attemptedFilename;
    }
</cfscript>