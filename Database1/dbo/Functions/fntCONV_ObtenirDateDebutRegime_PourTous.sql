/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service	: fntCONV_ObtenirDateDebutRegime_PourTous
Nom du service		: Obtenir la date de début de régime de toutes les conventions
But 				: Obtenir la date de début de régime des conventions.  La date de début de régime calculé dans ce
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

Exemple d’appel		:	SELECT * FROM [dbo].[fntCONV_ObtenirDateDebutRegime_PourTous](DEFAULT)

Historique des modifications:
    Date        Programmeur                 Description								 
    ----------  ------------------------    -----------------------------------------
    2016-09-01  Steeve Picard               Création du service
*********************************************************************************************************************/
CREATE FUNCTION dbo.fntCONV_ObtenirDateDebutRegime_PourTous
(
	@ConventionID  INT = NULL
)
RETURNS /*@Results*/ TABLE /*(
    ConventionID INT NOT NULL,
    dtDebutRegime DATE NULL
)*/
AS RETURN (
--BEGIN
     WITH
    	   -- Rechercher la date du premier FCB valide
        CTE_Cotisation as (
            SELECT
                Ct.UnitID, 
                dtOperRCB = MIN(CASE WHEN O.OperDate <= Ct.EffectDate THEN O.OperDate ELSE Ct.EffectDate END)
            FROM
                Un_Cotisation Ct
		      JOIN (
                    SELECT 
                        O.OperID, O.OperDate 
                    FROM
                        dbo.Un_Oper O
		              LEFT JOIN Un_OperCancelation OC1 ON OC1.OperID = O.OperID
		              LEFT JOIN Un_OperCancelation OC2 ON OC2.OperSourceID = O.OperID
                    WHERE
                        O.OperTypeID = 'RCB'
                        AND OC1.OperID IS NULL
	                   AND OC2.OperID IS NULL
                )  O ON O.OperID = Ct.OperID
            GROUP BY
                Ct.UnitID
        ),
        CTE_Unit as (
            SELECT  ConventionID, Min(dtFirst) as dtDebut
            FROM    (
                        SELECT  ConventionID, Min(dtInforceDateTIN) as dtFirst
                        FROM    dbo.Un_Unit
                        WHERE   dtInforceDateTIN IS NOT NULL
                          AND   ConventionID = IsNull(@ConventionID, ConventionID)
                        GROUP BY ConventionID
                        UNION
                        SELECT  ConventionID, IsNull(Max(dtOperRCB), Min(U.SignatureDate)) as dtFirst
                        FROM    dbo.Un_Unit U
                                LEFT JOIN CTE_Cotisation Ct ON Ct.UnitID = U.UnitID
                        WHERE   IsNull(dtOperRCB, U.SignatureDate) IS NOT NULL
                          AND   ConventionID = IsNull(@ConventionID, ConventionID)
                        GROUP BY ConventionID
                    ) X
            GROUP BY 
                X.ConventionID
        )
--     INSERT INTO @Results (ConventionID, dtDebutRegime)
	SELECT C.ConventionID, 
            CASE WHEN C.dtInforceDateTIN IS NULL THEN U.dtDebut
                 WHEN U.dtDebut IS NULL THEN C.dtInforceDateTIN
                 WHEN U.dtDebut > C.dtInforceDateTIN THEN C.dtInforceDateTIN
                 ELSE U.dtDebut
            END as dtDebutRegime
	FROM
        dbo.Un_Convention C
        LEFT JOIN CTE_Unit U ON U.ConventionID = C.ConventionID
     WHERE
        C.ConventionID = IsNull(@ConventionID, C.ConventionID)

	--IF IsNull(@bIncludeRIO, 0) <> 0
	--BEGIN
	--	DECLARE @dtDateDebuRegimetRIO	DATE = GetDate(),
	--			@idConventionRIO		INT = 0

	--	WHILE EXISTS(Select top 1 * From dbo.tblOPER_OperationsRIO Where iID_Convention_Destination = @iID_Convention And iID_Convention_Source > @idConventionRIO)
	--	BEGIN
	--		SELECT @idConventionRIO = Min(iID_Convention_Source) FROM dbo.tblOPER_OperationsRIO
	--		 WHERE iID_Convention_Destination = @iID_Convention And iID_Convention_Source > @idConventionRIO

	--		SET @dtDateDebuRegimetRIO = dbo.fnCONV_ObtenirDateDebutRegime(@idConventionRIO, NULL)

	--		IF @dtDateDebuRegimetRIO < @dtDate_Debut_Regime
	--			SET @dtDate_Debut_Regime = @dtDateDebuRegimetRIO
	--	END
	--END

	--RETURN
--END
)
