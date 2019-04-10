/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif
Nom du service		: 
But 				: Permet d'obtenir les groupes d'unités admissibles pour la commission sur l'actif
Facette				: CONV
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						@dtDate									Date 
						@iID_groupeUnite						ID du groupe d'unité
		  			

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						@tblGUadmissibleCommActif	SignatureDate				    Date de signature du groupe d'unité
						@tblGUadmissibleCommActif	UnitID							ID du groupe unité
						@tblGUadmissibleCommActif	iID_BeneficiaireOriginal	    ID du bénéficiaire original
						@tblGUadmissibleCommActif	BirthDate						Date de naissance du bénéficiaire original
						@tblGUadmissibleCommActif	UnitStateID					    Status du groupe d'unité

Exemple d'appel : 
				SELECT * FROM dbo.fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif(NULL, 724330, 6, '2016-07-01', null)
				SELECT * FROM dbo.fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif(NULL, NULL, 6, '2016-03-01', null)
	
Historique des modifications:
		Date		Programmeur			Description						Référence
		----------	-----------------	---------------------------  	------------
		2016-05-18	Maxime Martel		Création de la fonction		
        2016-06-08  Pierre-Luc Simard   Utilisation de Un_Cotisation.bInadmissibleComActif au lieu de Un_TIO.bOUTInadmissibleComActif
                                        Optimisation de la table Un_OperCancelation
        2016-06-16  Pierre-Luc Simard   On valide l'état du groupe d'unité pour tout le mois au lieu de la date demandée
        2016-06-21  Pierre-Luc Simard   Retrait des paramètres pour la rendre InLine
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif]
(
	@dtDate DATETIME = NULL,
	@iID_GroupeUniteID INT = NULL,
    @iAgeBenef INT,
    @dtSignature DATETIME
)
RETURNS TABLE
RETURN
(
    SELECT DISTINCT
		U.UnitID
    FROM Un_Unit U
    JOIN ( -- Le groupe d'unité a eu un de ces états au cours du mois
        SELECT DISTINCT 
            US.UnitID
        FROM Un_UnitUnitState US
        OUTER APPLY (
            SELECT 
                USS.UnitID,
                DateSuivante = MIN(USS.StartDate)
            FROM Un_UnitUnitState USS
            WHERE USS.UnitID = US.UnitID
                AND USS.StartDate > US.StartDate
            GROUP BY USS.UnitID
            ) USS
        WHERE (US.UnitID = @iID_GroupeUniteID OR @iID_GroupeUniteID IS NULL)
            AND dbo.fn_Mo_DateNoTime(US.StartDate) <= ISNULL(@dtDate, GETDATE()) 
            AND dbo.fn_Mo_DateNoTime(ISNULL(USS.DateSuivante, ISNULL(@dtDate, GETDATE()))) >= CAST(CAST(DATEPART(MONTH, ISNULL(@dtDate, GETDATE())) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR, ISNULL(@dtDate, GETDATE())) AS VARCHAR) AS DATE) 
            AND CHARINDEX(US.UnitStateID, 'REE,TRA,R1B,R2B,RBA,BRS,CPT,EPG,PAE,RCS,RIN,RIV', 1) <> 0            
            /*AND (US.StartDate BETWEEN CAST(CAST(DATEPART(MONTH, ISNULL(@dtDate, GETDATE())) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR, ISNULL(@dtDate, GETDATE())) AS VARCHAR) AS DATE) AND ISNULL(@dtDate, GETDATE())
                OR ISNULL(USS.DateSuivante, ISNULL(@dtDate, GETDATE())) BETWEEN CAST(CAST(DATEPART(MONTH, ISNULL(@dtDate, GETDATE())) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR, ISNULL(@dtDate, GETDATE())) AS VARCHAR) AS DATE) AND ISNULL(@dtDate, GETDATE()))
            AND CHARINDEX(US.UnitStateID, 'REE,TRA,R1B,R2B,RBA,BRS,CPT,EPG,PAE,RCS,RIN,RIV', 1) <> 0*/
        ) US ON US.UnitID = U.UnitID
	JOIN Mo_Human BO ON BO.HumanID = U.iID_BeneficiaireOriginal
    WHERE (U.UnitID = @iID_GroupeUniteID OR @iID_GroupeUniteID IS NULL)
        AND BO.BirthDate IS NOT NULL 
		AND dbo.fn_Mo_Age(BO.BirthDate, U.SignatureDate) >= @iAgeBenef
		AND U.SignatureDate >= @dtSignature
        AND NOT EXISTS  
            (
            SELECT DISTINCT
			    UU.UnitID
            FROM Un_Unit UU
		    JOIN Un_Cotisation CT ON CT.UnitID = UU.UnitID
		    JOIN Un_Oper O ON O.OperID = CT.OperID
		    LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID 
            LEFT JOIN Un_OperCancelation OCS ON OCS.OperSourceID = O.OperID
            WHERE UU.UnitID = U.UnitID  
                AND O.OperDate <= ISNULL(@dtDate, GETDATE())
                AND O.OperTypeID IN ('TIN', 'AJU', 'TRA')
                AND CT.bInadmissibleComActif <> 0
                AND OC.OperID IS NULL -- Pas une annulation
                AND OCS.OperID IS NULL -- Pas annulé
            )
)
