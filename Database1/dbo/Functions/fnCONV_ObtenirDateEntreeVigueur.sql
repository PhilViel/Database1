
/****************************************************************************************************
Code de service		:		fnCONV_ObtenirDateEntreeVigueur
Nom du service		:		1.1.22 Obtenir la date d'entrée en vigueur du régime
But					:		Obtenir la date d'entréee en vigueur d'un régime
Description			:		Ce service est utilisé par différents services et applications pour obtenir
							la date d'entrée en vigueur du régime
							
Facette				:		CONV
Reférence			:		Document P171U - Services du noyau de la facette CONV - Conventions

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						iID_Convention				Identifiant unique de la convention pour	Oui
													laquelle le calcul de la date d'entrée
													en vigueur est requis
Exemples d'appel:
				SELECT [dbo].[fnCONV_ObtenirDateEntreeVigueur](241420)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						S/O							dtDate_Entree_Vigueur						Date d'entrée en vigueur du régime
													
				
Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-16					Jean-François Gauthier					Création de la fonction
						
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fnCONV_ObtenirDateEntreeVigueur]
					(
					@iID_Convention	INT
					)
RETURNS	 DATETIME
AS
	BEGIN
		DECLARE @dtDate_Entree_Vigueur	DATETIME
		
		SELECT
			@dtDate_Entree_Vigueur = MIN(u.InForceDate)
		FROM
			dbo.Un_Unit u
		WHERE
			u.ConventionID = @iID_Convention

		RETURN @dtDate_Entree_Vigueur
	END
