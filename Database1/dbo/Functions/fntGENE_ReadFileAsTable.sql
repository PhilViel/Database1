/****************************************************************************************************
Code de service		:   fntGENE_ReadFileAsTable
Nom du service		:	Lire un fichier texte comme une table
But					:	Extraction du contenu d'un fichier pour le retourner comme une table où chaque enregistrement est une ligne du fichier
Facette				:	GENE

Parametres d'entrée :	
        Parametres					Description
        ----------                  ----------------
		@vcNomCompletFichier		Doit contenir le chemin complet du répertoire & le nom du fichier
		@iNbLignes  				Détermine le nombre de ligne désirant lire, par défaut 0 identique tout le fichier

Parametres de sortie : 
        Champs						Description
		------------------------    --------------------------
        iID_Line                    # de la ligne dans le fichier
        vcLine                      Contenu de la ligne du fichier

Historique des modifications :
			
        Date			Programmeur					Description
        ----------		------------------------    -------------------------------------------------
        2017-09-08		Steeve Picard           	Création de la function
*****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ReadFileAsTable]
(
    @vcPathAndFilename VARCHAR(max),
    @iNbLignes INT = 0
)
RETURNS @File TABLE
(
    [LineNo] INT IDENTITY(1, 1),
    line VARCHAR(8000)
)
AS
BEGIN

    DECLARE @objFileSystem INT,
            @objTextStream INT,
            @objErrorObject INT,
            @strErrorMessage VARCHAR(1000),
            @hr INT,
            @String VARCHAR(8000),
            @YesOrNo INT = 0,
            @Path VARCHAR(1000),
            @Filename VARCHAR(1000),
            @NbLine INT = 0,
            @bOpenAsUnicode bit = 0

    SELECT @strErrorMessage = 'creating the File System Object';
    EXECUTE @hr = sp_OACreate 'Scripting.FileSystemObject',
                              @objFileSystem OUT;

    IF @hr = 0
    BEGIN
        SELECT @objErrorObject = @objFileSystem,
                @strErrorMessage = 'Checking if path & file exists : "' + @vcPathAndFilename + '"'

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objFileSystem, 'GetParentFolderName',
                                      @Path OUT,
                                      @vcPathAndFilename

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objFileSystem, 'FolderExists',
                                      @YesOrNo OUT,
                                      @Path
        IF @YesOrNo = 0
            SELECT @hr = -1,
                   @objErrorObject = @objTextStream,
                   @strErrorMessage = 'folder not found"' + @Path + '"';

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objFileSystem, 'GetFilename',
                                      @Filename OUT,
                                      @vcPathAndFilename

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objFileSystem, 'FileExists',
                                      @YesOrNo OUT,
                                      @vcPathAndFilename
        IF @YesOrNo = 0
            SELECT @hr = -1,
                   @objErrorObject = @objTextStream,
                   @strErrorMessage = 'file not exists"' + @Filename + '"';
    END

    IF @hr = 0
    BEGIN
        SELECT @strErrorMessage = 'opening the Text File';

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objFileSystem, 'OpenTextFile',
                                      @objTextStream OUT,
                                      @vcPathAndFilename, 1, false

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objTextStream, 'ReadLine', @String OUTPUT;

        IF @hr = 0
        BEGIN
            If ASCII(SUBSTRING(@String, 1, 1)) = 255 AND ASCII(SUBSTRING(@String, 2, 1)) = 254
                SET @bOpenAsUnicode = 1
        END

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objFileSystem, 'OpenTextFile',
                                      @objTextStream OUT,
                                      @vcPathAndFilename, 1, false, @bOpenAsUnicode;
    END

    SELECT @objErrorObject = @objTextStream,
           @strErrorMessage = 'reading from the output file "' + @Filename + '"';
    WHILE @hr = 0
    BEGIN
        IF @hr = 0
            EXECUTE @hr = sp_OAGetProperty @objTextStream, 'AtEndOfStream',
                                           @YesOrNo OUTPUT;
        IF @hr <> 0 OR ISNULL(@YesOrNo, 0) <> 0
        BEGIN
            SELECT @hr = -1,
                   @strErrorMessage = 'finding out if there is more to read in "' + @Filename + '"';
            BREAK;
        END

        IF @hr = 0
            EXECUTE @hr = sp_OAMethod @objTextStream, 'Readline', 
                                      @String OUTPUT;

        INSERT INTO @File (line)
        VALUES (@String);

        SET @NbLine += 1

        IF @iNbLignes > 0
            IF @NbLine >= @iNbLignes 
                BREAK;
    END;

    IF @hr = 0
    BEGIN
        SET @strErrorMessage = 'closing the output file "' + @Filename + '"';
        EXECUTE @hr = sp_OAMethod @objTextStream, 'Close';
    END

    IF @hr <> 0
    BEGIN
        DECLARE @Source VARCHAR(255),
                @Description VARCHAR(255),
                @Helpfile VARCHAR(255),
                @HelpID INT;

        EXECUTE sp_OAGetErrorInfo @objErrorObject,
                                  @Source OUTPUT,
                                  @Description OUTPUT,
                                  @Helpfile OUTPUT,
                                  @HelpID OUTPUT;
        
        INSERT INTO @File (line)
        SELECT 'Error whilst ' + COALESCE(@strErrorMessage, 'doing something') + ', ' + COALESCE(@Description, '');
    END;

    EXECUTE sp_OADestroy @objTextStream;

    RETURN;
END;