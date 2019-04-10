/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_ScholarshipT4
Description         :	Rapport des T4 et relevés 8
Valeurs de retours  :	Dataset de données
Note                :	2004-06-28	Bruno Lapointe		Création
		ADX0000753	IA	2005-11-03	Bruno Lapointe		La procédure va chercher le montant du chèque
														dans les nouvelles tables au lieu de celles 
														d'UniSQL 
						2009-01-23	Donald Huppé		Céation de address1 et address2 et autres champs hardcodés
						2010-06-16	Pierre-Luc Simard	Modifications Province sans espace, Code postal Null, Montant 
						2011-05-19	Donald Huppé		GLPI 5165 : Récupérer le bénéficiaire en date de l'opération du PAE
						2012-01-19	Eric Michaud		Ajout de CB.iID_Nouveau_Beneficiaire
						2012-11-22	Pierre-Luc Simard	Ajout du regroupement par fiducie
						2013-01-09	Pierre-Luc Simard	Vérification de tous les chèques pour une opération, pas juste le dernier.
						2015-01-26	Donald Huppé		ajout des montants de DDD

-- exec RP_UN_ScholarshipT4Formulatrix
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipT4Formulatrix_tempNonResidant] 
AS
BEGIN

	select
		iID_Convention,
		iID_Changement_Beneficiaire,
		iID_Nouveau_Beneficiaire,
		StartDate, 
		EndDate = isnull(min(EndDate),getdate())
	into #tmp1
	from (	
		select
			CBDebut.iID_Changement_Beneficiaire,CBDebut.iID_Nouveau_Beneficiaire,CBDebut.iID_Convention,StartDate = CBDebut.dtDate_Changement_Beneficiaire, EndDate = CBFin.dtDate_Changement_Beneficiaire
		from 
			tblCONV_ChangementsBeneficiaire CBDebut
			left join tblCONV_ChangementsBeneficiaire CBFin on CBDebut.iID_Convention = CBFin.iID_Convention and CBFin.dtDate_Changement_Beneficiaire >= CBDebut.dtDate_Changement_Beneficiaire  and CBFin.iID_Changement_Beneficiaire > CBDebut.iID_Changement_Beneficiaire
		) VV
	group by 
		iID_Convention,
		iID_Changement_Beneficiaire,
		iID_Nouveau_Beneficiaire,
		StartDate

	--CREATE index #ind on #tmp1(iID_Convention)

	SELECT 
		CB.iID_Nouveau_Beneficiaire,
		BeneficiaryLastName = RTRIM(BH.LastName),
		BeneficiaryFirstName = RTRIM(BH.FirstName),
		BeneficiarySocialNumber = RTRIM(BH.SocialNumber),
		Fiducie = F.vcDescription,
		ChequeAmount = SUM(CH.fAmount),
		ChequeAmount_FOIS100 = CONVERT(INT ,SUM(CH.fAmount) * 100),
		--BeneficiaryAddress = RTRIM(A.Address),
		BeneficiaryAddress1 = case when len(RTRIM(A.Address)) > 30 
								then left(RTRIM(A.Address), len(RTRIM(A.Address)) - CHARINDEX (' ' , reverse(RTRIM(A.Address)), len(RTRIM(A.Address))-30) ) 
								else RTRIM(A.Address) end,
		BeneficiaryAddress2 = case when len(RTRIM(A.Address)) > 30 
								then rtrim(ltrim(RIGHT(RTRIM(A.Address), CHARINDEX (' ' , reverse(RTRIM(A.Address)), len(RTRIM(A.Address))-30)))) 
								else '' end,
		AdresseEstTronquée = case when len(RTRIM(A.Address)) > 30 and len(rtrim(ltrim(RIGHT(RTRIM(A.Address), CHARINDEX (' ' , reverse(RTRIM(A.Address)), len(RTRIM(A.Address))-30))))) > 30 Then 1 else 0 end,
		BeneficiaryCity = RTRIM(A.City),
		BeneficiaryState = ' (' + RTRIM(A.StateName) + ')',
		BeneficiaryState2 = LTRIM(RTRIM(ISNULL(A.StateName,'ZZ'))),
		BeneficiaryZipCode = dbo.fn_Mo_FormatZIP(ISNULL(RTRIM(UPPER(A.ZipCode)),''), A.CountryID),
		Country = A.CountryID,
		Entreprise = '138959168RP0001',
		Enregistrement = 'Q-100609-5921-RS-0001',
		Relevé1 = 'X',
		Relevé16 = 'X',
		CodeRevenu = 2,
		TypeBenef = '1 Particulier',
		ChampZero = 0,
		ChampVide = ''

	FROM (
		SELECT
			V.OperID,
			C.fAmount
		FROM (
			SELECT 
				L.OperID,
				C.iCheckNumber,
				iCheckID = MAX(C.iCheckID)
			FROM Un_ScholarshipPmt SP
			JOIN Un_Oper O ON O.OperID = SP.OperID AND O.OperTypeID IN ('PAE','AVC')
			JOIN Un_OperLinkToCHQOperation L ON SP.OperID = L.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			GROUP BY 
				L.OperID,
				C.iCheckNumber
			) V
		JOIN CHQ_Check C ON C.iCheckID = V.iCheckID
		WHERE C.iCheckStatusID IN (4,6)
			AND (YEAR(C.dtEmission) = (YEAR(GETDATE())-1))

		UNION ALL

		SELECT 
			OperID = IdOperationFinanciere
			,fAmount = Montant
		FROM DecaissementDepotDirect
		WHERE	 
			DateDecaissement IS NOT NULL
			AND (YEAR(DateDecaissement) = (YEAR(GETDATE())-1)) -- décaissé durant l'année
			AND (DateAnnule IS NULL AND DateEffetRetourne IS NULL AND DateRejete IS NULL) -- vraiment décaissé

		) CH
	JOIN Un_Oper O ON O.OperID = CH.OperID
	JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
	JOIN Un_Scholarship S ON S.ScholarshipID = P.ScholarshipID
	JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
	JOIN Un_Plan PL ON PL.PlanID = C.PlanID
	JOIN tblCONV_RegroupementsRegimes F ON F.iID_Regroupement_Regime = PL.iID_Regroupement_Regime
	join #tmp1 CB on C.ConventionID = CB.iID_Convention and O.dtSequence_Operation between CB.StartDate AND CB.EndDate
	--JOIN dbo.Mo_Human BH ON BH.HumanID = C.BeneficiaryID
	JOIN dbo.Mo_Human BH ON CB.iID_Nouveau_Beneficiaire = BH.HumanID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = BH.AdrID
	WHERE 
		BH.ResidID <> 'CAN'
		-- Cas où le chèque a déjà été émis (avant l'an passée) alors on ne fait pas de T4 pour la réémission, donc on l'exlu ici
		and ch.operid not in(
			SELECT L.OperID
			FROM Un_ScholarshipPmt SP
			JOIN Un_Oper O ON O.OperID = SP.OperID AND O.OperTypeID IN ('PAE','AVC')
			JOIN Un_OperLinkToCHQOperation L ON SP.OperID = L.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			where C.iCheckStatusID not IN (4,6) 
				and (YEAR(C.dtEmission) < (YEAR(GETDATE())-1))
			)
	GROUP BY 
		CB.iID_Nouveau_Beneficiaire,
		BH.LastName,
		BH.FirstName,
		BH.SocialNumber,
		F.vcDescription,
		A.Address,
		A.City,
		A.StateName,
		A.ZipCode,
		A.CountryID
	HAVING SUM(CH.fAmount) > 0
	ORDER BY
		BH.LastName,
		BH.FirstName,
		F.vcDescription
END


