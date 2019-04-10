/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service     : psIQEE_ImporterFichierContenu
Nom du service      : Importer le contenu d'un fichier
But                 : Importer le contenu du fichier, une ligne par enregistrement dans la table de destination.
Facette             : IQÉÉ

Paramètres d’entrée :   Paramètre               Description
                        --------------------    -----------------------------------------------------------------
                        @PathName               Chemin du répertoire dans lequel se trouve le fichier physique à importer.
                        @Filename               Nom du fichier physique à importer.
                        @TableName              Nom de la table dans laquelle sera importé le contenu du fichier 
                        @FieldTerminator        Spécifie la marque de fin de champ à utiliser pour les fichiers de données de type char et widechar
                        @RowTerminator          Spécifie le délimiteur de fin de ligne à utiliser pour les fichiers de données de type char et widechar
                        @CodePage               Indique la page de codes des données dans le fichier (ACP | OEM | RAW | code_page)
                        @DataFileType           Spécifie que BULK INSERT réalise l'opération d'importation en utilisant la valeur définie pour le type de fichier de données ( char | native | widechar | widenative)
                        @FirstRow               Numéro de la première ligne à charger
                        @LastRow                Numéro de la dernière ligne à charger (0 si tout le contenu est importé)

Exemple d’appel        :    EXECUTE dbo.psIQEE_ImporterFichierContenu '\\gestas2\departements\IQEE\Fichiers\Reçus\',
                                                                      'P11412491782009032617280720090717132854.err',
                                                                      '#TB_FileData'

Historique des modifications:
        Date        Programmeur                         Description                                
        ----------  ----------------------------------  -----------------------------------------
        2016-04-28  Steeve Picard                       Création du service                            
***********************************************************************************************************************/
CREATE PROC [dbo].[psIQEE_ImporterFichierContenu] (
    @PathName varchar(500),
	@Filename varchar(100),
	@TableName varchar(100),
	@FieldTerminator varchar(5) = '\t',
	@RowTerminator varchar(5) = '\n',
	@CodePage varchar(5) = '1252',
	@DataFileType varchar(5) = 'char',
	@FirstRow int = 1,
	@LastRow int = 0
)
AS 
BEGIN
	DECLARE @SqlCmd varchar(max)
	DECLARE @vcCrLf varchar(2) = Char(13) + char(10)
	DECLARE @iResultat int

    -- Valider les paramètres
    IF IsNull(@PathName, '') = '' OR IsNull(@Filename, '') = ''
        RaisError('Le répertoire et le nom du fichier sont requis dans les paramètres d''entrées.', 10, 1)
	
	IF RIGHT(@PathName, 1) <> '\'
	    SET @PathName += '\'

    EXECUTE @iResultat = dbo.psGENE_FichierRepertoireExiste @PathName, @Filename
    IF @iResultat <> 3
    BEGIN        
        RaisError('Le fichier physique à importer n''existe pas ou est inaccessible.', 16, 2)
        Return
    END

	SET @SqlCmd = 'BULK INSERT ' + @TableName + @vcCrLf +
				  'FROM ''' + @PathName + @Filename + '''' + @vcCrLf +
				  'WITH (' + @vcCrLf +
				  '      FIELDTERMINATOR = ''' + @FieldTerminator + ''',' + @vcCrLf +
				  '      ROWTERMINATOR = ''' + @RowTerminator + ''',' + @vcCrLf +
				  '      CODEPAGE = ''' + @CodePage + ''',' + @vcCrLf +
				  '      DATAFILETYPE = ''' + @DataFileType + ''',' + @vcCrLf +
				  '      FIRSTROW = ' + LTrim(STR(@FirstRow)) + ',' + @vcCrLf +
				  --'      ROWS_PER_BATCH = 5000,' + @vcCrLf +
				  --'      KEEPNULLS,' + @vcCrLf +
				  '      TABLOCK' + @vcCrLf +
				  '     )'

    IF @LastRow > 0 
        SET @SqlCmd = REPLACE(@SqlCmd, 'TABLOCK', 'LASTROW = ' + LTrim(STR(@LastRow)) + ',' + @vcCrLf + '      TABLOCK')
        
    BEGIN TRY 
	    EXECUTE (@SqlCmd)
	END TRY
	BEGIN CATCH
        PRINT @SqlCmd
	    DECLARE @SqlErr varchar(1000) = ERROR_MESSAGE() + ' (Severity:' + LTrim(Str(ERROR_SEVERITY(), 2)) + ', Status:' + LTrim(Str(ERROR_STATE(), 2)) + ')'
	    RaisError(@SqlErr, 16, 2)
	END CATCH
END