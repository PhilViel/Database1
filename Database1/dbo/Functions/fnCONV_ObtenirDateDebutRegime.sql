/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirDateDebutRegime
Nom du service		: Obtenir la date de début de régime 
But 				: Obtenir la date de début de régime d’une convention.  La date de début de régime calculé dans ce
					  service, est la date de début de régime d'UniAccès.  Elle sert entre autre à déterminer la date
					  de fin de régime.  Contrairement au service fnIQEE_ObtenirDateDebutRegime qui de sont coté, permet
					  de ne pas tenir compte du FCB/RCB pour tenir compte des dépôts faits durant la période où la
					  convention était en statut transitoire.  Cette dernière utilise la date d'entrée en vigueur du
					  premier groupe d'unités de la convention pour ne pas avoir à reprendre les transactions d'environ
					  6400 conventions où la date de signature est ultérieure à la date d’entrée en vigueur du premier
					  groupe d’unité.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant unique de la convention pour laquelle le calcul de la
													date de début de régime est requis.

Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirDateDebutRegime](300000)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							dtDate_Fin_Regime				Si le service se réalise avec succès,
																					c’est la date de début de régime.
						S/O							iCode_Retour					Code de retour en cas d’erreur.
																						-1 – Un paramètre est absent ou
																							 n’existe pas.
																						-2 – Toute autre erreur.

Historique des modifications:
		Date			Programmeur							Description								 
		------------	----------------------------------	-----------------------------------------
		2009-02-26		Éric Deshaies						Création du service
		2012-01-27		Éric Deshaies						Modification à la détermination de la date de début de régime.  La date de début de
															régime doit tenir compte de la date du premier FCB/RCB valide de la convention et
															ne plus tenir compte de la date d'entrée en vigueur du premier groupe d'unité.
		2015-10-01		Steeve Picard						Ajout du paramètre «@bIncludeRIO» pour tenir compte de la date de début de régime des RIO

*********************************************************************************************************************/
CREATE FUNCTION dbo.fnCONV_ObtenirDateDebutRegime
(
	@iID_Convention	INT,
	@bIncludeRIO	BIT = 0
)
RETURNS DATETIME
AS
BEGIN
	-- Valider les paramètres
	IF @iID_Convention IS NULL OR
	   NOT EXISTS(SELECT *
				  FROM dbo.Un_Convention 
				  WHERE ConventionID = @iID_Convention)
		RETURN -1
	
	DECLARE @dtDate_Debut_Regime DATETIME,
			@dtDate_Debut_Regime_TIN DATETIME

	SET @dtDate_Debut_Regime = NULL

	-- Rechercher la date du premier FCB valide
	SELECT @dtDate_Debut_Regime = MIN(CASE WHEN O.OperDate <= CO.EffectDate THEN O.OperDate ELSE CO.EffectDate END)
	FROM dbo.Un_Unit U
		 JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
		 JOIN Un_Oper O ON O.OperID = CO.OperID
					   AND O.OperTypeID = 'RCB'
		 LEFT JOIN Un_OperCancelation OC1 ON OC1.OperID = O.OperID
		 LEFT JOIN Un_OperCancelation OC2 ON OC2.OperSourceID = O.OperID
	WHERE U.ConventionID = @iID_Convention
	  AND OC1.OperID IS NULL
	  AND OC2.OperID IS NULL

	-- S'il n'y a pas de FCB valide
	IF @dtDate_Debut_Regime IS NULL
		BEGIN
			-- Rechercher la date de signature du contrat
			SELECT @dtDate_Debut_Regime = MIN(U.SignatureDate)
			FROM dbo.Un_Unit U 
			WHERE U.ConventionID = @iID_Convention
			  AND U.SignatureDate IS NOT NULL
		END

	-- Rechercher une date de début de régime issue d'un transfert IN
	SELECT @dtDate_Debut_Regime_TIN = MIN(ISNULL(dtDate,0))
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
			  AND U.dtInforceDateTIN <> '1899-12-30') T
	WHERE T.dtDate IS NOT NULL

	-- Si la date de début de régime du transfert IN est plus petite que la date de début de régime déterminé par le FCB ou la date de signature,
	-- prendre la plus petite date soit la date de début de régime provenant d'un transfert IN
	IF @dtDate_Debut_Regime_TIN IS NOT NULL AND
	   @dtDate_Debut_Regime_TIN < ISNULL(@dtDate_Debut_Regime,GETDATE())
		SET @dtDate_Debut_Regime = @dtDate_Debut_Regime_TIN

	IF IsNull(@bIncludeRIO, 0) <> 0
	BEGIN
		DECLARE @dtDateDebuRegimetRIO	DATE = GetDate(),
				@idConventionRIO		INT = 0

		WHILE EXISTS(Select top 1 * From dbo.tblOPER_OperationsRIO Where iID_Convention_Destination = @iID_Convention And iID_Convention_Source > @idConventionRIO)
		BEGIN
			SELECT @idConventionRIO = Min(iID_Convention_Source) FROM dbo.tblOPER_OperationsRIO
			 WHERE iID_Convention_Destination = @iID_Convention And iID_Convention_Source > @idConventionRIO

			SET @dtDateDebuRegimetRIO = dbo.fnCONV_ObtenirDateDebutRegime(@idConventionRIO, NULL)

			IF @dtDateDebuRegimetRIO < @dtDate_Debut_Regime
				SET @dtDate_Debut_Regime = @dtDateDebuRegimetRIO
		END
	END

	-- Retourner la date de début de régime
	RETURN @dtDate_Debut_Regime
END
