/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntOPER_ObtenirTypesRendements
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
				SELECT * FROM dbo.fntOPER_ObtenirTypesRendements(NULL)


Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-08-06		Jean-François Gauthier		Création de la fonction			1.5.1 dans le P171U - Services du noyau de la facette OPER - Opérations
		
****************************************************************************************************/
CREATE FUNCTION dbo.fntOPER_ObtenirTypesRendements
	(
		@vcLangue					VARCHAR(3)	
	)
RETURNS @tTypeRendement TABLE
						(
						tiID_Type_Rendement	TINYINT
						,vcCode_Rendement	VARCHAR(3)
						,vcDescription		VARCHAR(100)
						)
AS
	BEGIN
-- TO DO : VOIR CE QU'ON FAIT AVEC LE PARAMÈTRE DE LANGUE
		INSERT INTO @tTypeRendement
		(
			tiID_Type_Rendement
			,vcCode_Rendement
			,vcDescription	
		)
		SELECT
			tr.tiID_Type_Rendement
			,tr.vcCode_Rendement
			,tr.vcDescription	
		FROM 
			dbo.tblOPER_TypesRendement tr
		ORDER BY
			tr.siOrdrePresentation
		RETURN
	END
