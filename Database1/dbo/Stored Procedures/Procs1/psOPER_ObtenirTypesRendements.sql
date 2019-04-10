/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_ObtenirTypesRendements
Nom du service		: TBLOPER_TYPESRENDEMENTS 
But 				: Permet d'obtenir tous les types de rendement correspondant à la langue reçue en paramètre
Description			: Cette fonction est appelée pour obtenir les types de rendement selon la langue désirée.

Facette				: OPER
Référence			: Noyau-OPER

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						VCLANGUE					Oui			Détermine la langue des informations retournées
		  			

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblOPER_TypesRendements		tiID_Type_Rendement				Identifiant du type de rendement
													vcCode_Rendement				Code du type de rendement
													vcDescription					Description du type de rendement

Exemple d'appel : 
				EXEC dbo.psOPER_ObtenirTypesRendements NULL


Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-11-27		Jean-François Gauthier		Création du service
		
****************************************************************************************************/
CREATE PROCEDURE dbo.psOPER_ObtenirTypesRendements
	(
		@vcLangue	VARCHAR(3)	
	)
AS
	BEGIN
		SET NOCOUNT ON

		SELECT 
			tiID_Type_Rendement	
			,vcCode_Rendement	
			,vcDescription		
		FROM 
			dbo.fntOPER_ObtenirTypesRendements(@vcLangue)
	END
