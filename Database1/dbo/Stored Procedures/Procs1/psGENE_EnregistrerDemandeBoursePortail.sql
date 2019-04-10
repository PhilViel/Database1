/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_EnregistrerDemandeBoursePortail
Nom du service		: Enregistrer une Demande de Bourse faite via le Portail
But 				: Enregistrer une Demande de Bourse faite via le Portail
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcNoConfirmation
						dtDateCreationDemande
						iIDBeneficiaire
						vcUserName
						vcPrenomBeneficiaire
						vcNomBeneficiaire
						bQualifie
						bResident
						vcBourse
						vcConventions				Chaine de caractères contenant les 3 informations suivantes séparées par des virgules (NoConvention, Prénom et nom souscripteur, nb d'unités)
													et répéter l'info pour chaque convention en séparant chaque bloc de convention par un point-virgule
						vcCommentaires
						bAttestation
						vcPreuveReleve
						vcPreuveInscription

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					iID_DemandeBoursePortail = Traitement réussi
																					-2 = Erreur de traitement
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-04-28		Donald Huppé						Création
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_EnregistrerDemandeBoursePortail]
		(
		@vcNoConfirmation varchar(40),
		@dtDateCreationDemande datetime,
		@iIDBeneficiaire INT,
		@vcUserName varchar(40),
		@vcPrenomBeneficiaire varchar(50),
		@vcNomBeneficiaire varchar(50),
		@bQualifie bit,
		@bResident bit,
		@vcBourse varchar(15),
		@vcConventions varchar(2000),
		@vcCommentaires varchar(250),
		@bAttestation bit,
		@vcPreuveReleve varchar(250),
		@vcPreuveInscription varchar(250)
		)
AS
BEGIN
	SET NOCOUNT ON;


DECLARE @iCode_Retour INT


	BEGIN TRANSACTION

	BEGIN TRY

		insert INTO tblGENE_DemandeBoursePortail (
				vcNoConfirmation,
				dtDateCreationDemande,
				iIDBeneficiaire,
				vcUserName,
				vcPrenomBeneficiaire,
				vcNomBeneficiaire,
				bQualifie,
				bResident,
				vcBourse,
				vcConventions,
				vcCommentaires,
				bAttestation,
				vcPreuveReleve,
				vcPreuveInscription
				)
		values (
				@vcNoConfirmation,
				@dtDateCreationDemande,
				@iIDBeneficiaire,
				@vcUserName,
				@vcPrenomBeneficiaire,
				@vcNomBeneficiaire,
				@bQualifie,
				@bResident,
				@vcBourse,
				@vcConventions,
				@vcCommentaires,
				@bAttestation,
				@vcPreuveReleve,
				@vcPreuveInscription 
				)

		SET @iCode_Retour = (SELECT SCOPE_IDENTITY());

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- UNE ERREUR TECHNIQUE S'EST PRODUITE. LA TRANSACTION EST ANNULÉE
		-- ET ON RETOURNE LE CODE D'ERREUR -2
		ROLLBACK TRANSACTION
		SET @iCode_Retour = -2;
	END CATCH

	-- RETOURNE la cvaleur de iID_DemandeBoursePortail 
	SELECT @iCode_Retour AS iCode_Retour;




END


/*
SELECT * FROM tblGENE_DemandeBoursePortail
delete FROM tblGENE_DemandeBoursePortail
CREATE TABLE tblGENE_DemandeBoursePortail (
		iID_DemandeBoursePortail int IDENTITY(1,1) NOT NULL,
		vcNoConfirmation varchar(40),
		dtDateCreationDemande datetime,
		iIDBeneficiaire INT,
		vcUserName varchar(40),
		vcPrenomBeneficiaire varchar(50),
		vcNomBeneficiaire varchar(50),
		bQualifie bit,
		bResident bit,
		vcBourse varchar(15),
		vcConventions varchar(2000),
		vcCommentaires varchar(250),
		bAttestation bit,
		vcPreuveReleve varchar(250),
		vcPreuveInscription varchar(250)
	)
*/

/*
exec psGENE_EnregistrerDemandeBoursePortail
		
		@vcNoConfirmation = 'noconf',
		@dtDateCreationDemande ='2011-04-25',
		@iIDBeneficiaire =2,
		@vcUserName = '2',
		@vcPrenomBeneficiaire = 'LePrénom',
		@vcNomBeneficiaire = 'LeNom',
		@bQualifie = 1,
		@bResident =1,
		@vcBourse ='toutes',
		@vcConventions = '345667, John Fortin, 2.00',
		@vcCommentaires = 'Le veux mes bourses viarge',
		@bAttestation = 1,
		@vcPreuveReleve = 'PreuveRelev.pdf',
		@vcPreuveInscription = 'PreuveInscription.pdf'
		*/
