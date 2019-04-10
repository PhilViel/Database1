
/****************************************************************************************************
Code de service		:		fnCONV_ObtenirOperIDConventionBEC
Nom du service		:		fnCONV_ObtenirOperIDConventionBEC
But					:		Retourne le OperID le plus récent sur la convention du bénéficiaire sur laquelle
							le BEC est actif.
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
		
Exemples d'appel:
				SELECT [dbo].[fnCONV_ObtenirOperIDConventionBEC]()

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						Un_Convention				@iID_Beneficiaire							Identifiant du bénéficiaire
						N/A							@iCodeRetour								> 0 (contient l'identifiant de l'opération)
																								= -1 Aucune donnée présente
																						
	

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-12-07					Jean-François Gauthier					Création du serveir

 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fnCONV_ObtenirOperIDConventionBEC]
	(
		@iID_Beneficiaire	INT
	)
RETURNS INT
AS
	BEGIN
		DECLARE 
			@iID_Oper		INT
		
		SELECT 
			@iID_Oper = MAX(o.OperID) 
		FROM 
			dbo.Un_Oper o
			INNER JOIN dbo.Un_CESP400 ce 
				ON o.OperID = ce.OperID
		WHERE 
			o.OperTypeID = 'BEC'
			AND
			ce.ConventionID = dbo.fnCONV_ObtenirConventionBEC(@iID_Beneficiaire, 0, NULL)	
			AND
			ce.tiCESP400TypeID = 24

		RETURN ISNULL(@iID_Oper, -1)
	END
