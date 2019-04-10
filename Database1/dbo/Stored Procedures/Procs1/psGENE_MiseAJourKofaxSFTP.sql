/****************************************************************************************************
Code de service		:		dbo.psGENE_MiseAJourKofaxSFTP
Nom du service		:		psGENE_MiseAJourKofaxSFTP
But					:		Génère la liste des répertoires des souscripteurs ou bénéficiaires pour l'application Kofax
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						vcType						Type de fichier demandé						OUI
													(S=Souscripteur, B=Bénéficiaires, C=Conventions)			
						vcNomFichier				Nom du fichier à créer (CSV)
													
Exemple d'appel:

	EXEC psGENE_MiseAJourKofaxSFTP 'S', 'C:\DTS\Kofax\souscripteurs.csv'	
	EXEC psGENE_MiseAJourKofaxSFTP 'B', 'C:\DTS\Kofax\beneficiaires.csv'	
	EXEC psGENE_MiseAJourKofaxSFTP 'C', 'C:\DTS\Kofax\conventions.csv'	

Parametres de sortie :  Table											Champs							Description
					    -----------------								---------------------------		--------------------------
						N/A
						@iRetour										=1								Traitement effectué avec succès
																		=-1								Traitement en erreur

						Les champs inscrits dans le fichier CSV sont les suivants :

						vcDossier				    = Dossier du plan de classification pour le bénéficiaire ou le souscripteur (Nom, Prénom, ID)

Historique des modifications :
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-04-20					Pierre-Luc Simard						Création de la procédure	
						2012-12-13					Pierre-Luc Simard						Ajout des conventions				
						2012-12-20					Pierre-Luc Simard						Ajout de champs pour les conventions
						2013-04-19					Pierre-Luc Simard						Vider les tables tblTEMP_KofaxBenef (anciennement tKofaxDossiersBenef),
																											tblTEMP_KofaxSousc (anciennement tKofaxDossiersSousc)
																											tblTEMP_KofaxConv (anciennement tKofaxDossiersConv)
																											au lieu de les supprimer et les refaire
  ****************************************************************************************************/

CREATE PROCEDURE dbo.psGENE_MiseAJourKofaxSFTP(
	@vcType varchar(1),
	@vcNomFichier varchar(100)) 
AS
	BEGIN

		SET NOCOUNT ON

		DECLARE 
			@iRetour			INT
			,@iErrSeverity		INT
			,@iErrState			INT
			,@vcErrmsg			VARCHAR(1024)
			,@iCodeErreur		INT			
	
		DECLARE
			@tConvention	TABLE (ConventionID INT)
		
		DECLARE @str VARCHAR(1000) 
    /*
		IF object_id('dbo.tKofaxDossiersBenef') is not null
			DROP TABLE tKofaxDossiersBenef
		IF object_id('dbo.tKofaxDossiersSousc') is not null
			DROP TABLE tKofaxDossiersSousc
		IF object_id('dbo.tKofaxDossiersConv') is not null
			DROP TABLE tKofaxDossiersConv
	*/
		TRUNCATE TABLE tblTEMP_KofaxBenef		
		TRUNCATE TABLE tblTEMP_KofaxSousc
		TRUNCATE TABLE tblTEMP_KofaxConv
		
		BEGIN TRY
			--Détruire le fichier actuel 
			exec('exec master..xp_cmdshell ''del '+@vcNomFichier+'''')
		
			-- Création du fichier CSV		
			IF @vcType = 'B'
			BEGIN	
				/*CREATE TABLE tblTEMP_KofaxBenef (
					vcDossier VARCHAR(100))*/
				INSERT INTO tblTEMP_KofaxBenef (
					vcDossier)	
				SELECT
					vcDossier = replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(H.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(H.firstname)),' ','_') + '_' + cast(H.humanid as varchar(20))),'.',''),',',''),'&','Et')
				FROM dbo.Un_Beneficiary B
				LEFT JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
				--Créer le nouveau fichier	
				exec SP_ExportTableToExcelWithColumns 'UnivBase', 'tblTEMP_KofaxBenef', @vcNomFichier, 'RAW', 0
			END
			ELSE IF @vcType = 'S'
			BEGIN
				/*CREATE TABLE tblTEMP_KofaxSousc (
					vcDossier VARCHAR(100))*/
				INSERT INTO tblTEMP_KofaxSousc (
					vcDossier)	
				SELECT
					vcDossier = replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(H.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(H.firstname)),' ','_') + '_' + cast(H.humanid as varchar(20))),'.',''),',',''),'&','Et')
				FROM dbo.Un_Subscriber S
				JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
				--Créer le nouveau fichier	
				exec SP_ExportTableToExcelWithColumns 'UnivBase', 'tblTEMP_KofaxSousc', @vcNomFichier, 'RAW', 0
			END
			ELSE IF @vcType = 'C'
			BEGIN
				/*CREATE TABLE tblTEMP_KofaxConv (
					ConventionNo VARCHAR(15),
					SubscriberID INT,
					BeneficiaryID INT,
					vcDossier VARCHAR(100),
					SLastName VARCHAR(50),
					SFirstname VARCHAR(35),
					UnitQty MONEY)*/
				INSERT INTO tblTEMP_KofaxConv (
					ConventionNo,
					SubscriberID,
					BeneficiaryID,
					vcDossier,
					SLastName,
					SFirstname,
					UnitQty)	
				SELECT
					C.ConventionNo,
					C.SubscriberID,
					C.BeneficiaryID,
					vcDossier = replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(H.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(H.firstname)),' ','_') + '_' + cast(H.humanid as varchar(20))),'.',''),',',''),'&','Et'),
					H.LastName,
					H.FirstName,
					UnitQty = ROUND(ISNULL(U.UnitQty, 0), 3)
				FROM dbo.Un_Convention C
				JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
				JOIN (
					SELECT 
						U.ConventionID,
						UnitQty = SUM(U.UnitQty)
					FROM dbo.Un_Unit U
					GROUP BY U.ConventionID
					) U ON U.ConventionID = C.ConventionID
				ORDER BY 
					C.ConventionNo
				--Créer le nouveau fichier	
				exec SP_ExportTableToExcelWithColumns 'UnivBase', 'tblTEMP_KofaxConv', @vcNomFichier, 'RAW', 0
			END
														
			SET @iRetour = 1
		
		END TRY
		
		BEGIN CATCH
				SELECT
					@vcErrmsg			= REPLACE(ERROR_MESSAGE(),'%',' ')
					,@iErrState			= ERROR_STATE()
					,@iErrSeverity		= ERROR_SEVERITY()
					,@iCodeErreur		= ERROR_NUMBER()
					,@iRetour			= -1

				RAISERROR	(@vcErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH

		RETURN @iRetour
		
	END


