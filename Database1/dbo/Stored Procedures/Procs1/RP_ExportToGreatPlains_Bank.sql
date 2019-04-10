/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                 :	RP_ExportToGreatPlains_Bank
						
Description         :	Pour l'exportation vers les fichiers TXT Bank_D ou Bank_H
Valeurs de retours  :	Dataset
							

Note                :	2008-12-09	Donald Huppé
						2009-01-22	Donald Huppé		Correction du type de chèque dans la gestion de BankH
						2009-02-10	Donald Huppé		Modification pour enlever les doublons dans la gestion de BankH
						2009-02-12	Donald Huppé		Modification pour la concaténation du prénom et nom dans le cas de valeur NULLL et gestion des apostrophes
						2010-07-09	Pierre-Luc Simard	Modification des comptes pour la gestion des fiducies
						2010-08-24	Pierre-Luc Simard	Ajout du champ vcCode_Chequier_GreatPlains pour le fichier Bank_H
						2010-08-26	Pierre-Luc Simard	Ajout du paramètre pour générer les fichiers par code de chéquier
						2016-02-23	Pierre-Luc Simard	Ajout du compte 00-1104-2-00
                        2018-10-19  Pierre-Luc Simard   Ajout du paramètre pour la gestion temporaire de la nouvelle charte comptable

-- exec RP_ExportToGreatPlains_Bank '2010-08-01','2010-09-01','OUT','H', 'FID-REEEFLEX-2'
-- exec RP_ExportToGreatPlains_Bank '2018-01-01','2018-10-19','RES','D', 'FID-REEEFLEX-2', 1
-- exec RP_ExportToGreatPlains_Bank '2018-01-01','2018-10-19','RES','D', 'FID-REEEFLEX-2', 0
****************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_ExportToGreatPlains_Bank] (
	@DateFrom MoDateOption,  
	@DateTo MoDateOption,
	@Type nvarchar(20), -- Type de chèque
	@BANQ  nvarchar(1), -- D ou H ou NULL pour les 2
	@vcCode_Chequier nvarchar(50), -- Code de chéquier dans Great Plains
    @bNouveauCompte BIT = 0) -- Indique si on doit utiliser les nouveaux ou les anciens comptes (Temporaire)
AS
BEGIN



if @BANQ = 'D' or @BANQ is null

	BEGIN -- Fich_Bank_D 
	
	SELECT 
		NoCheque = CHQ_Check.iCheckNumber, 
		Compte = CASE WHEN ISNULL(@bNouveauCompte, 0) = 1 THEN ISNULL(AN.NewAccount, CHQ_OperationDetail.vcAccount) ELSE CHQ_OperationDetail.vcAccount END, 
        Montant = SUM(-CHQ_OperationDetail.fAmount) 
	FROM 
		CHQ_Check 
		JOIN CHQ_CheckOperationDetail ON CHQ_Check.iCheckID = CHQ_CheckOperationDetail.iCheckID 
		JOIN CHQ_OperationDetail ON CHQ_CheckOperationDetail.iOperationDetailID = CHQ_OperationDetail.iOperationDetailID
		JOIN CHQ_Operation ON CHQ_OperationDetail.iOperationID = CHQ_Operation.iOperationID
		JOIN Un_OperLinkToCHQOperation ON CHQ_Operation.iOperationID = Un_OperLinkToCHQOperation.iOperationID
		LEFT JOIN Un_Plan P ON P.PlanID = CHQ_Check.iID_Regime
		LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
        LEFT JOIN (
            SELECT DISTINCT AN.vcAccountNumber, AMTN.NewAccount
            FROM Un_AccountMoneyType AMT 
            JOIN Un_Account A ON A.iAccountID = AMT.iAccountID
            JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID
            JOIN Un_AccountMoneyType_TEMP AMTN ON AMTN.OLDAccountMoneyTypeID = AMT.iAccountMoneyTypeID
            ) AN ON AN.vcAccountNumber = CHQ_OperationDetail.vcAccount
	WHERE ISNULL(RR.vcCode_Chequier_GreatPlains,'ROYALE') = @vcCode_Chequier 	
	GROUP BY 
		CHQ_Check.iCheckNumber, 
		CHQ_OperationDetail.vcAccount, 
        AN.NewAccount,
		CHQ_Check.dtEmission, 
		CHQ_Operation.vcRefType, 
		CHQ_Check.iCheckStatusID
	HAVING 
		CHQ_OperationDetail.vcAccount NOT IN ('00-1100-0-00','00-1105-1-00','00-1105-2-00','00-1105-3-00', '00-1104-2-00', -- Anciens comptes
                                              '00-0-1010-001','00-1-1000-001','00-2-1000-001','00-3-1000-001','00-2-1000-001') -- Nouveaux comptes
		AND CHQ_Check.iCheckStatusID = 4
		AND CHQ_Check.dtEmission Between @DateFrom And @DateTo
		AND (
			(@Type = 'RIN' AND CHQ_Operation.vcRefType = 'RIN' ) OR
			(@Type = 'Bourses' AND CHQ_Operation.vcRefType in ('PAE','RGC','AVC') ) OR
			(@Type = 'RES' AND CHQ_Operation.vcRefType = 'RES' ) OR
			(@Type = 'RET' AND CHQ_Operation.vcRefType = 'RET' ) OR
			(@Type = 'OUT' AND CHQ_Operation.vcRefType = 'OUT' )
			)

	END -- Fich_Bank_D


if @BANQ = 'H' or @BANQ is null

	BEGIN -- Fich_Bank_H
	
	SELECT 
		distinct
		CHQ_Check.iCheckNumber AS NumChq, 
		1 AS EntreeSortie, 
		CHQ_Check.iCheckNumber, 
		DateChq = case when len(cast(Day(dtEmission) as varchar(2))) = 1 then '0' + cast(Day(dtEmission) as varchar(2)) else cast(Day(dtEmission) as varchar(2)) end + '/' 
				+ case when len(cast(month(dtEmission) as varchar(2))) = 1 then '0' + cast(month(dtEmission) as varchar(2)) else cast(month(dtEmission) as varchar(2)) end + '/' 
				+ cast(Year(dtEmission) as varchar(4)), 
		ltrim(rtrim(isnull(replace(vcFirstName,'''',' '),'') + ' ' + isnull(replace(vcLastName,'''',' '),''))) AS PrenomNom, 
		CHQ_Operation.vcDescription + case when @Type = 'RIN' then ' - RI' when @Type in ('PAE','RGC','AVC') then ' - Bourse' else ' - ' + @Type  end  AS Description,
		CHQ_Check.fAmount,
		ISNULL(RR.vcCode_Chequier_GreatPlains,'ROYALE') AS vcCode_Chequier_GreatPlains
	FROM 
		CHQ_Check 
		JOIN CHQ_CheckOperationDetail ON CHQ_Check.iCheckID = CHQ_CheckOperationDetail.iCheckID
		JOIN CHQ_OperationDetail ON CHQ_CheckOperationDetail.iOperationDetailID = CHQ_OperationDetail.iOperationDetailID
		JOIN CHQ_Operation ON CHQ_OperationDetail.iOperationID = CHQ_Operation.iOperationID
		--------------2009-02-10------------Début
		JOIN (
			SELECT 
				CO.icheckID,
				iOperationID = MAX(COD.iOperationID)
			FROM 
				CHQ_Check C
				JOIN CHQ_CheckOperationDetail CO ON c.iCheckID = CO.iCheckID
				JOIN CHQ_OperationDetail COD ON CO.iOperationDetailID = COD.iOperationDetailID
				JOIN CHQ_Operation COP ON COD.iOperationID = COP.iOperationID
			WHERE 
				(
				(@Type = 'RIN' AND COP.vcRefType = 'RIN' ) OR
				(@Type = 'Bourses' AND COP.vcRefType in ('PAE','RGC','AVC') ) OR
				(@Type = 'RES' AND COP.vcRefType = 'RES' ) OR
				(@Type = 'RET' AND COP.vcRefType = 'RET' ) OR
				(@Type = 'OUT' AND COP.vcRefType = 'OUT' )
				)
			GROUP BY CO.icheckID
			) MAXOp ON MAXOp.icheckID = CHQ_Check.iCheckID and MAXOp.iOperationID = CHQ_Operation.iOperationID
		--------------2009-02-10------------Fin		
		LEFT JOIN Un_Plan P ON P.PlanID = CHQ_Check.iID_Regime
		LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	WHERE 
		CHQ_Check.dtEmission between @DateFrom and @DateTo
		AND CHQ_Check.iCheckStatusID = 4
		AND ISNULL(RR.vcCode_Chequier_GreatPlains,'ROYALE') = @vcCode_Chequier 
		AND (
			(@Type = 'RIN' AND CHQ_Operation.vcRefType = 'RIN' ) OR
			(@Type = 'Bourses' AND CHQ_Operation.vcRefType in ('PAE','RGC','AVC') ) OR
			(@Type = 'RES' AND CHQ_Operation.vcRefType = 'RES' ) OR
			(@Type = 'RET' AND CHQ_Operation.vcRefType = 'RET' ) OR
			(@Type = 'OUT' AND CHQ_Operation.vcRefType = 'OUT' )
			)

	END -- Fich_Bank_H

END

