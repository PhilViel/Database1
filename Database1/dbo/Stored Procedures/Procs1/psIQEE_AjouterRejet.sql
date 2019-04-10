/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_AjouterRejet
Nom du service		: Ajouter un rejet
But 				: Ajouter une raison de rejet à une transaction rejetée en vertu des validations.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Fichier_IQEE			Identifiant du fichier de transactions qui est à l’origine de la
													transaction et du rejet.
						iID_Convention				Identifiant de la convention de la transaction en rejet.
						iID_Validation				Identifiant de la validation à l’origine du rejet.
						vcDescription				Description du message de validation.
						vcValeur_Reference			Valeur qui a servie de référence à la validation.
						vcValeur_Erreur				Valeur du champ en erreur.
						iID_Lien_Vers_Erreur_1		Identifiant qui sert de lien vers un enregistrement d'UniAccès qui
													est à l'origine de l'erreur.
						iID_Lien_Vers_Erreur_2		Identifiant qui sert de lien vers un enregistrement d'UniAccès qui
													est à l'origine de l'erreur.
						iID_Lien_Vers_Erreur_3		Identifiant qui sert de lien vers un enregistrement d'UniAccès qui
													est à l'origine de l'erreur.

Exemple d’appel		:	Ce service doit uniquement être appelé par les procédures "psIQEE_CreerTransactions..." et la
						procédure "psIQEE_CreerFichierAnnee".

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-02-05		Éric Deshaies						Création du service							
		2009-10-27		Éric Deshaies						Amélioration de la performance.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_AjouterRejet] 
(
	@iID_Fichier_IQEE INT,
	@iID_Convention INT,
	@iID_Validation INT,
	@vcDescription VARCHAR(300),
	@vcValeur_Reference VARCHAR(200),
	@vcValeur_Erreur VARCHAR(200),
	@iID_Lien_Vers_Erreur_1 INT,
	@iID_Lien_Vers_Erreur_2 INT,
	@iID_Lien_Vers_Erreur_3 INT
)
AS
BEGIN
	-- Ajouter le rejet
	INSERT INTO tblIQEE_Rejets
			   ([iID_Fichier_IQEE]
			   ,[iID_Convention]
			   ,[iID_Validation]
			   ,[vcDescription]
			   ,[vcValeur_Reference]
			   ,[vcValeur_Erreur]
			   ,[iID_Lien_Vers_Erreur_1]
			   ,[iID_Lien_Vers_Erreur_2]
			   ,[iID_Lien_Vers_Erreur_3])
		 VALUES
			   (@iID_Fichier_IQEE
			   ,@iID_Convention
			   ,@iID_Validation
			   ,ISNULL(@vcDescription,'')
			   ,@vcValeur_Reference
			   ,@vcValeur_Erreur
			   ,@iID_Lien_Vers_Erreur_1
			   ,@iID_Lien_Vers_Erreur_2
			   ,@iID_Lien_Vers_Erreur_3)
END




