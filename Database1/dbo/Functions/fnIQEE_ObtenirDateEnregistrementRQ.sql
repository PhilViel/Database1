/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnIQEE_ObtenirDateEnregistrementRQ
Nom du service		: Obtenir la date d'enregistrement au programme de l'IQÉÉ
But 				: Obtenir la date d'enregistrement d’une convention au programme de l'IQÉÉ.
					  Cette date d'enregistrement à l'IQÉÉ est affiché à l'interface d'UniAccès afin quelle soit utilisée sur
					  les formulaires des transferts OUT.
					  La présente fonction de l'IQÉÉ permet de ne pas tenir compte du FCB/RCB pour tenir compte des
					  dépôts faits durant la période où la convention était en statut transitoire.  Cette dernière
					  utilise la date d'entrée en vigueur du premier groupe d'unités de la convention pour ne pas avoir
					  à reprendre les transactions d'environ 6400 conventions où la date de signature est ultérieure à
					  la date d’entrée en vigueur du premier groupe d’unité.  On ne tient compte de la date d'entrée en
					  vigueur du premier groupe d'unité uniquement pour les conventions avant 2012.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant unique de la convention pour laquelle le calcul de la
													date d'enregistrement est requis.

Exemple d’appel		:	SELECT [dbo].[fnIQEE_ObtenirDateEnregistrementRQ](300000)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							dtDate_EnregistrementRQ			Si le service se réalise avec succès,
																					c’est la date d'enregistrement à l'IQÉÉ.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-08		Éric Deshaies						Création du service							
		2011-03-25		Éric Deshaies						Ne pas tenir compte de la date 1899-12-30
															dans les dates de transfert IN.
		2012-01-27		Éric Deshaies						Modification du but dans les commentaires.
															On ne tient compte de la date d'entrée en
															vigueur du premier groupe d'unité uniquement
															pour les conventions avant 2012.
		2012-06-06		Éric Michaud						Modification projet septembre 2012
		2012-09-21		Stéphane Barbeau					Ajout de la condition AND C.ConventionID <> C2.ConventionID pour 
															éviter les TINs erronnés (ConventionID Source = ConventionID Destination) 
															de causer des boucles infinies (No more lock classes available from transaction).
		2012-11-14		Stéphane Barbeau					Modification du SELECT de la clause TIN pour SELECT top 1 afin de contourner les 
															conventions ayant plusieurs TIN faits le même jour.
		2013-02-01		Stéphane Barbeau					Régression du code à la version du 2012-01-27.  
															Décision prise par S. Barbeau et G.Komenda.  
															Le code a été renversé parce que nous ne traitons pas présentement les T04.  
															Les modifications faites après le 2012-01-27 n'ont pas leur raison d'être jusqu'à nouvel ordre.
		2016-05-04		Steeve Picard						Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateDebutRegime»
***********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnIQEE_ObtenirDateEnregistrementRQ]
(
	@iID_Convention	INT
)
RETURNS DATETIME
AS
BEGIN
	-- Valider les paramètres
	IF @iID_Convention IS NULL OR
	   NOT EXISTS(SELECT *
				  FROM dbo.Un_Convention 
				  WHERE ConventionID = @iID_Convention)
		RETURN NULL
	
	DECLARE @dtDate_EnregistrementRQ DATETIME

	-- Trouver la date de base de calcul
	SELECT @dtDate_EnregistrementRQ = MIN(ISNULL(dtDate,0))
	FROM  (SELECT C.dtInforceDateTIN AS dtDate
			FROM dbo.Un_Convention C
			WHERE C.ConventionID = @iID_Convention
			  AND C.dtInforceDateTIN IS NOT NULL
			  AND C.dtInforceDateTIN <> '1899-12-30'
			UNION ALL
			SELECT	MIN(U.dtInforceDateTIN) AS dtDate
			FROM dbo.Un_Unit U 
			WHERE U.ConventionID = @iID_Convention
			  AND U.dtInforceDateTIN IS NOT NULL
			  AND U.dtInforceDateTIN <> '1899-12-30'
			UNION ALL
			SELECT	MIN(U.SignatureDate) AS dtDate
			FROM dbo.Un_Unit U 
			WHERE U.ConventionID = @iID_Convention
			  AND U.SignatureDate IS NOT NULL
			UNION ALL
			SELECT	MIN(U.InForceDate) AS dtDate
			FROM dbo.Un_Unit U 
			WHERE U.ConventionID = @iID_Convention
			  AND U.InForceDate IS NOT NULL
			  AND U.ConventionID <= 397154) T  -- Tenir compte de la date de début des opérations financières du premier groupe d'unité uniquement avant 2012
	WHERE T.dtDate IS NOT NULL

	-- Retourner la date de début de régime
	RETURN @dtDate_EnregistrementRQ
END
