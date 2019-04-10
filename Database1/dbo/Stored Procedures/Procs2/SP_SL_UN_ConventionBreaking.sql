 
/****************************************************************************************************
Code de service		:		[SP_SL_UN_ConventionBreaking]
Nom du service		:		[SP_SL_UN_ConventionBreaking]
But					:		Donne la liste des arrêts de paiement d'une convention
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConventionID				ID Unique de la convention

Exemple d'appel:
					
		
Parametres de sortie : Dataset

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-06-01					Bruno Lapointe							Création du service
		2011-04-11					Corentin Menthonnex						Ajout de paramètres d'historisation
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_SL_UN_ConventionBreaking] (
	@ConventionID INTEGER) -- ID Unique de la convention
AS
BEGIN
	SELECT 
		BreakingID,
		BreakingTypeID,
		BreakingStartDate,
		BreakingEndDate,
		BreakingReason,		
		iID_Utilisateur_Creation,														-- 2011-12 : + CM
		vcUtilisateur_Creation = dbo.fn_Mo_HumanName(iID_Utilisateur_Creation),			-- 2011-12 : + CM
		dtDate_Creation_Operation,														-- 2011-12 : + CM
		iID_Utilisateur_Modification,													-- 2011-12 : + CM
		vcUtilisateur_Modification = dbo.fn_Mo_HumanName(iID_Utilisateur_Modification),	-- 2011-12 : + CM
		dtDate_Modification_Operation,													-- 2011-12 : + CM
		ConventionID
	FROM Un_Breaking
	WHERE ConventionID = @ConventionID
	ORDER BY 
		BreakingStartDate DESC, 
		BreakingID DESC
END;
