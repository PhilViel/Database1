/****************************************************************************************************
Code de service		:		psGENE_ObtenirTraductionPourRapport
Nom du service		:		Obtenir les traduction pour un rapport
But					:		affichier les libellé d'un rapport selon la langue passée en paramètre.
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@vcNomRapport				Nom du fichier RDL du rapport
						@vcLangID					ID de la langue demandée

Exemple d'appel:
                
                EXEC psGENE_ObtenirTraductionPourRapport 'RapListeClientParRep_VersionExcel','FRA'

Parametres de sortie :	Table						Champs										Description
						-----------------			---------------------------					-----------------------------
						tblGENE_Traductions			iID_Enregistrement							Id de l'enregistrement qui correspond au no du libellé dans le rapport
													vcTraduction								Traduction du libellé
                   
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-08-19					Donald Huppé							Création du service
						
****************************************************************************************************/
	
CREATE PROCEDURE [dbo].[psGENE_ObtenirTraductionPourRapport] (
	@vcNomRapport VARCHAR(500),
	@vcLangID VARCHAR(3)
	)
AS

BEGIN
	
	SELECT 
		iID_Enregistrement, 
		vcTraduction
	FROM 
		tblGENE_Traductions
	WHERE 
		vcNom_table = LTRIM(RTRIM(@vcNomRapport))
		and vcID_Langue = @vcLangID

	UNION
	
	SELECT 
		iID_Enregistrement = 0,
		vcTraduction = vcLangueRapportSSRS
	FROM 
		MO_Lang
	WHERE 
		LangID = @vcLangID

END