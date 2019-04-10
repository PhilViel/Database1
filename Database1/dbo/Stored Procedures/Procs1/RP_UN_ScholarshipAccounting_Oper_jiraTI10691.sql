/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc
Nom                 :	RP_UN_ScholarshipAccounting_Oper
Description         :	Rapport de comptabilité des bourses Par opération et non par chèque
Valeurs de retours  :	Dataset de données

Note                :	2010-02-02	Donald Huppé	Création
						2010-05-05	Donald Huppé	Correction suite à l'implantation.
						2010-06-21	Donald Huppé	Correction de la gestion des annulations.
						2010-11-02	Donald Huppé	GLPI 4523
													Correction du calcul de fTotal
						2011-02-10	Donald Huppé	GLPi 5051 : faire un "left join" sur un_conventionoper car certaines bourses n'ont que de la subvention et rien d'autre
						2011-03-23	Donald Huppé	GLPI 5263 : Remplacer PlanDesc par groupe de régime. On garde le même nom de champs pour ne pas avoir à modifier le rapport SSRS
						2011-07-15	Donald Huppé	GLPI 5803 : retrouver le bénéficiaire de la convention en date du PAE
						2011-07-22	Pierre-Luc Simard	Ajout du ORDER BY dans le dernier SELECT
						2011-08-30	Donald Huppé	Correction de la recherche du bénéficiaire en date du PAE
						2014-09-30	Donald Huppé	glpi 12448 : Ajout du Id DDD et Date décaissement dans l'info du chèque
						2014-10-23	Donald Huppé	glpi 12448 : BeneficiaireCHQ = destinataire du DDD ou du cheque
						2014-10-27	Donald Huppé	glpi 12786 : Si une DDD existe (peu importe son statut, on met idDDD = 0 afin que ça ne sorte pas dans le groupe ND
						2014-11-04	Donald Huppé	glpi 12792 : exclure les DDD 'Refusée','Rejetée','Annulée', 
													et prendre le max (DDD.id) pour être certain d'en avoir un seul
						2014-11-06	Donald Huppé	glpi 12797 : changer appel de fntOPER_ObtenirEtatDDD	
						2014-12-04	Donald Huppé	glpi 12978 : ajouter le destinataire du chèque non imprimé
						2015-08-31	Donald Huppé	MIN(TypePmt) au lieu de MAX(TypePmt) : afin que "chèque" ou "DDD" remplace ND dans la portion RGC d'un meêm PAE du dataset #TMPBourse
						2015-09-17	Donald Huppé	glpi 15619 : ajout du champ DDDNo
                        2017-02-27  Maxime Martel   TI-7022 :  ajout de la cohorte dans le rapport
                        2017-12-12  Pierre-Luc Simard   Ajout du compte RST dans le compte BRS
                        2018-11-02  Pierre-Luc Simard   N'est plus utilisée

exec RP_UN_ScholarshipAccounting_Oper '2016-01-01','2016-12-31' , 'B'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipAccounting_Oper_jiraTI10691] (
	@StartDate DATETIME, -- Date de début de l'intervalle des opérations
	@EndDate DATETIME, -- Date de fin de l'intervalle des opérations
	@cOrder	CHAR(1))	--Tri du rapport : 
				--S = Nom, prénom du souscripteur suivi du numéro de convention, 
				--B = Nom, prénom du bénéficiaire suivi du numéro de convention.) 
				
AS
BEGIN

    SELECT 1/0

    /*

	SELECT 

		TypeChq,
		iCheckHistoryID = 0, -- POUR COMPATIBILITÉ AVEC ANCIENNE SP
		iCheckID,
		iCheckStatusID = 0, -- POUR COMPATIBILITÉ AVEC ANCIENNE SP
		OperID = PAEOperID,
		ScholarshipID,

		PlanDesc,
		PlanType,
		BourseNo = 'Bourse ' + RTRIM(CAST(ScholarshipNo AS VARCHAR)),
		conventionNo,
		Beneficiaire = ISNULL(BLastName,'')+', '+ISNULL(BFirstName,''),
		Souscripteur = ISNULL(SLastName,'')+', '+ISNULL(SFirstName,''),
		UnitQty,
		--ChequeDate = dbo.FN_CRQ_DateNoTime(chq.dtEmission),
		ChequeDate = case 
					when chq.dtEmission is not NULL then dbo.FN_CRQ_DateNoTime(chq.dtEmission)
					when ddd.DateDecaissement is not NULL then dbo.FN_CRQ_DateNoTime(ddd.DateDecaissement)
					else NULL
					end,
		PAEOperDate,
		ChequeNo = ISNULL(CAST(chq.iCheckNumber AS VARCHAR(30)),''),
		/*
		ChequeNo = case 
					when chq.iCheckNumber IS NOT NULL then CAST(chq.iCheckNumber AS VARCHAR(30))
					when ddd.id IS NOT NULL then CAST(-1 * ddd.id AS VARCHAR(30)) -- multiplier par -1 pour distinguer des numéros de chèque
					END,
		*/
		TypePmt = case 
					when chq.iCheckNumber IS NOT NULL and ddd.id IS NULL then 'Chèque'
					when ddd.id IS NOT NULL and chq.iCheckNumber IS NULL then 'DDD'
					when ddd.id IS NOT NULL and chq.iCheckNumber IS NOT NULL then 'Chèque_DDD'
					Else 'ND'
					END,
		AdvanceAmount,
		ScholarshipAmount,
		fINM,
		fCESG,
		fACESG,
		fCLB,
		fINS,
		fISP,
		fIBC,
		fITR,
		fIRIOnVersedInt,
		fRGC,
		fCBQ,
		fMMQ,
		fIQI,
		fMIM,
		fICQ,
		fIMQ,
		fIIQ,
		fIII,
		mCredit_Base_Verse,
		mMajoration_Verse,
		mInterets_RQ_IQEE,
		mInterets_RQ_IQEE_Maj,
		fTotal,

		BeneficiaireChq = isnull(ISNULL(vcPayeeName,DestinataireDDD),''),
		BLastName,
		BFirstName,
		SLastName,
		SFirstName,
		DDDNo = isnull(CAST(-1 * ddd.id AS VARCHAR(30)),'') + case when ddd.id is not null and isnull(ddd.QteDDD,0) > 1 then ' (' + CAST(ddd.QteDDD as VARCHAR (4)) + ')' else '' end, -- multiplier par -1 pour distinguer des numéros de chèque
        Cohorte
	INTO #TMPBourse

	FROM (
	
			SELECT
				TypeChq,
				v.conventionID,
				v.conventionNo,
				u.UnitQty,
				SLastname = HS.lastname,
				SFirstname = HS.firstname,
				BLastname = HB.lastname,
				BFirstname = HB.firstname,

				PlanDesc,
				PlanType,
				ScholarshipID,
				ScholarshipNo,
				--OperID,
				PAEOperID = MAX(PAEOperID), 
				PAEOperDate = MAX(PAEOperDate), 
				AdvanceAmount = SUM(AVC),
				ScholarshipAmount = SUM(PAEBRS)- SUM(RGCBRS), -- ceci additionne les 2 montant car RGCBRS est négatif

				fINM = SUM(case when PAEOperID <> 0 then INMI else 0 end),

				fCESG ,
				fACESG,
				fCLB,
				
				fINS = SUM(case when PAEOperID <> 0 then INS else 0 end) + SUM(case when PAEOperID <> 0 then IST else 0 end),
				fISP = SUM(case when PAEOperID <> 0 then ISP else 0 end),
				fIBC = SUM(case when PAEOperID <> 0 then IBC else 0 end),
				fITR = SUM(case when PAEOperID <> 0 then ITR else 0 end),
				fIRIOnVersedInt = SUM(case when PAEOperID <> 0 then INMC else 0 end),
				fRGC = SUM(RGC),
				fCBQ = SUM(case when PAEOperID <> 0 then CBQ else 0 end),
				fMMQ = SUM(case when PAEOperID <> 0 then MMQ else 0 end),
				fIQI = SUM(case when PAEOperID <> 0 then IQI else 0 end),
				fMIM = SUM(case when PAEOperID <> 0 then MIM else 0 end),
				fICQ = SUM(case when PAEOperID <> 0 then ICQ else 0 end),
				fIMQ = SUM(case when PAEOperID <> 0 then IMQ else 0 end),
				fIIQ = SUM(case when PAEOperID <> 0 then IIQ else 0 end),
				fIII = SUM(case when PAEOperID <> 0 then III else 0 end),
				mCredit_Base_Verse = SUM(case when PAEOperID <> 0 then CBQ else 0 end),
				mMajoration_Verse = SUM(case when PAEOperID <> 0 then MMQ else 0 end),
				mInterets_RQ_IQEE = SUM(case when PAEOperID <> 0 then IQI else 0 end) + SUM(case when PAEOperID <> 0 then MIM else 0 end) + SUM(case when PAEOperID <> 0 then ICQ else 0 end) + SUM(case when PAEOperID <> 0 then IIQ else 0 end) + SUM(case when PAEOperID <> 0 then III else 0 end),
				mInterets_RQ_IQEE_Maj = SUM(case when PAEOperID <> 0 then IMQ else 0 end),
				fTotal = 
					SUM(AVC) + --SUM(case when PAEOperID <> 0 then AVC else 0 end) +
					SUM(PAEBRS)- SUM(RGCBRS) +  --SUM(case when PAEOperID <> 0 then PAEBRS else 0 end)-SUM(case when PAEOperID <> 0 then RGCBRS else 0 end) +
					SUM(case when PAEOperID <> 0 then INMI else 0 end) +
					fCESG +
					fACESG +
					fCLB +
					SUM(case when PAEOperID <> 0 then INS else 0 end) + SUM(case when PAEOperID <> 0 then IST else 0 end) +
					SUM(case when PAEOperID <> 0 then ISP else 0 end) +
					SUM(case when PAEOperID <> 0 then IBC else 0 end) +
					SUM(case when PAEOperID <> 0 then ITR else 0 end) +
					SUM(case when PAEOperID <> 0 then INMC else 0 end) +
					SUM(RGC) + 
					SUM(case when PAEOperID <> 0 then CBQ else 0 end) +
					SUM(case when PAEOperID <> 0 then MMQ else 0 end) +
					SUM(case when PAEOperID <> 0 then IQI else 0 end) +
					SUM(case when PAEOperID <> 0 then MIM else 0 end) +
					SUM(case when PAEOperID <> 0 then ICQ else 0 end) +
					SUM(case when PAEOperID <> 0 then IMQ else 0 end) +
					SUM(case when PAEOperID <> 0 then IIQ else 0 end) +
					SUM(case when PAEOperID <> 0 then III else 0 end),
               Cohorte = C.YearQualif
		
			FROM ( 
				
				SELECT
					TypeChq = CASE WHEN O.OperTypeID in( 'PAE','RGC') then 'PAE' else 'AVC' end, -- glpi 4523
					C.conventionID,
					C.conventionNo,
					PlanDesc = RR.vcDescription,
					PlanType = CASE WHEN P.PlanTypeID = 'IND' THEN 'Individuel' ELSE 'Collectif' END,
					S.ScholarshipID,
					S.ScholarshipNo,
					PAEOperID = CASE WHEN O.OperTypeID = 'PAE' /* in ('PAE','AVC')*/ THEN O.OperID ELSE 0 END, -- glpi 4523
					PAEOperDate = CASE WHEN O.OperTypeID = 'PAE' /* in ('PAE','AVC')*/ THEN O.OperDate ELSE 0 END, -- glpi 4523
					O.OperID,
					O.OperTypeID,
					ConventionOperTypeID

					,fCESG = -ISNULL(CESP.fCESG,0) 
					,fACESG = -ISNULL(CESP.fACESG,0)
					,fCLB = -ISNULL(CESP.fCLB,0)

					,RGC = CASE WHEN O.OperTypeID = 'RGC' THEN ConventionOperAmount ELSE 0 END,
					RGCBRS = CASE WHEN O.OperTypeID = 'RGC' and ConventionOperTypeID IN ('BRS', 'RST') THEN ConventionOperAmount ELSE 0 END,
					PAEBRS = CASE WHEN O.OperTypeID = 'PAE' and ConventionOperTypeID IN ('BRS', 'RST') THEN -ConventionOperAmount ELSE 0 END,
					AVC = CASE WHEN ConventionOperTypeID = 'AVC' THEN -ConventionOperAmount ELSE 0 END,
					INMI = CASE WHEN ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'IND' THEN -ConventionOperAmount ELSE 0 END,
					INS = CASE WHEN ConventionOperTypeID = 'INS' THEN -ConventionOperAmount ELSE 0 END,
					IST = CASE WHEN ConventionOperTypeID = 'IST' THEN -ConventionOperAmount ELSE 0 END,
					ISP = CASE WHEN ConventionOperTypeID = 'IS+' THEN -ConventionOperAmount ELSE 0 END,
					IBC = CASE WHEN ConventionOperTypeID = 'IBC' THEN -ConventionOperAmount ELSE 0 END,
					ITR = CASE WHEN ConventionOperTypeID = 'ITR' THEN -ConventionOperAmount ELSE 0 END,
					INMC = CASE WHEN ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'COL' THEN -ConventionOperAmount ELSE 0 END,
					CBQ = CASE WHEN ConventionOperTypeID = 'CBQ' THEN -ConventionOperAmount ELSE 0 END,
					MMQ = CASE WHEN ConventionOperTypeID = 'MMQ' THEN -ConventionOperAmount ELSE 0 END,
					IQI = CASE WHEN ConventionOperTypeID = 'IQI' THEN -ConventionOperAmount ELSE 0 END,
					MIM = CASE WHEN ConventionOperTypeID = 'MIM' THEN -ConventionOperAmount ELSE 0 END,
					ICQ = CASE WHEN ConventionOperTypeID = 'ICQ' THEN -ConventionOperAmount ELSE 0 END,
					IMQ = CASE WHEN ConventionOperTypeID = 'IMQ' THEN -ConventionOperAmount ELSE 0 END,
					IIQ = CASE WHEN ConventionOperTypeID = 'IIQ' THEN -ConventionOperAmount ELSE 0 END,
					III = CASE WHEN ConventionOperTypeID = 'III' THEN -ConventionOperAmount ELSE 0 END	

				FROM 
					UN_Scholarship S 
					JOIN dbo.Un_Convention C on C.ConventionID = S.ConventionID
					JOIN UN_Plan P ON P.PlanID = C.PlanID
					JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
					JOIN UN_ScholarshipPmt SP on SP.scholarShipID = S.scholarShipID
					LEFT JOIN UN_CESP CESP on CESP.OperID = SP.operID
					JOIN UN_Oper O on SP.OperID = O.OperID
					LEFT JOIN UN_ConventionOper CO on O.OperID = CO.OperID -- GLPi 5051 : faire un "left join" plutot qu'un "Join"
				WHERE O.OPERTYPEid IN ('PAE','RGC','AVC')
				--and c.conventionno in ('R-20041001005',  'R-20050118034')
					AND O.Operdate between @StartDate and @EndDate
				) V
				JOIN dbo.Un_Convention c on v.conventionid = c.conventionid
				JOIN (
				SELECT 
					C.ConventionID, 
					UnitQty = SUM(U.UnitQty)
				FROM dbo.Un_Convention C 
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				GROUP BY 
					C.ConventionID
				) U ON U.ConventionID = C.ConventionID
				JOIN dbo.mo_human hs on c.subscriberid = hs.humanid
				JOIN dbo.mo_human hb on c.beneficiaryid = hb.humanid
			GROUP BY 
				TypeChq,
				v.conventionID,
				v.conventionNo,
				u.UnitQty,
				HS.lastname,
				HS.firstname,
				HB.lastname,
				HB.firstname,
				PlanDesc,
				PlanType,
				ScholarshipNo,
				ScholarshipID,
				fCESG,
				fACESG,
				fCLB
				,OperID
                ,C.YearQualif
			) V2
		
		LEFT JOIN (
			SELECT 
				op.operid, 
				C.iCheckID,
				ichecknumber, 
				dtemission,
				vcPayeeName = ISNULL(H.LastName,'')+', '+ISNULL(H.FirstName,'')
			FROM				
				Un_OperLinkToCHQOperation op
				JOIN CHQ_OperationDetail OD ON OD.iOperationID = op.iOperationID 
				JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
				JOIN chq_check c on COD.iCheckid = c.iCheckid
				LEFT JOIN dbo.Mo_Human H ON H.HumanID = C.iPayeeID
			WHERE  c.icheckstatusid = 4 
			GROUP BY 
				op.operid, 
				C.iCheckID, 
				ichecknumber, 
				dtemission,
				ISNULL(H.LastName,'')+', '+ISNULL(H.FirstName,'')
		 ) chq on V2.PAEOperID = chq.operid 

		left join (
			select 
				ddd2.Id
				,ddd2.IdOperationFinanciere
				,ddd2.DateDecaissement
				,QteDDD
				,DestinataireDDD = hd.LastName +', ' + hd.FirstName
			from (
				select
					ddd.IdOperationFinanciere
					,id =max(ddd.id) 
					,QteDDD = count(distinct ddd.id)
				from DecaissementDepotDirect ddd
				join DBO.fntOPER_ObtenirEtatDDD (NULL,@EndDate) t on ddd.Id = t.id
				join un_oper o on ddd.IdOperationFinanciere = o.OperID
				--where t.Etat not in ('Refusée','Rejetée','Annulée')
				group by ddd.IdOperationFinanciere
				) tt
			join DecaissementDepotDirect ddd2 on tt.id = ddd2.Id
			JOIN dbo.Mo_Human hd on ddd2.IdDestinataire = hd.HumanID
			)ddd ON V2.PAEOperID = ddd.IdOperationFinanciere
--select * from #TMPBourse

	SELECT 
		TypeChq,
		ScholarshipID,
		iCheckHistoryID, -- POUR COMPATIBILITÉ AVEC ANCIENNE SP
		iCheckID = MAX(iCheckID),
		iCheckStatusID, -- POUR COMPATIBILITÉ AVEC ANCIENNE SP
		OperID = MAX(OperID), -- glpi 4523
		PlanDesc,
		PlanType,
		BourseNo,
		conventionNo,
		Beneficiaire,
		Souscripteur,
		UnitQty,
		ChequeDate = MAX(ChequeDate),
		PAEOperDate = MAX(PAEOperDate),
		ChequeNo = MAX(ChequeNo),
		AdvanceAmount = SUM(AdvanceAmount),
		ScholarshipAmount = SUM(ScholarshipAmount),
		fINM = SUM(fINM),
		fCESG = SUM(fCESG),
		fACESG = SUM(fACESG),
		fCLB = SUM(fCLB),
		fINS = SUM(fINS),
		fISP = SUM(fISP),
		fIBC = SUM(fIBC),
		fITR = SUM(fITR),
		fIRIOnVersedInt = SUM(fIRIOnVersedInt),
		fRGC = SUM(fRGC),
		fCBQ = SUM(fCBQ),
		fMMQ = SUM(fMMQ),
		fIQI = SUM(fIQI),
		fMIM = SUM(fMIM),
		fICQ = SUM(fICQ),
		fIMQ = SUM(fIMQ),
		fIIQ = SUM(fIIQ),
		fIII = SUM(fIII),
		mCredit_Base_Verse = SUM(mCredit_Base_Verse),
		mMajoration_Verse = SUM(mMajoration_Verse),
		mInterets_RQ_IQEE = SUM(mInterets_RQ_IQEE),
		mInterets_RQ_IQEE_Maj = SUM(mInterets_RQ_IQEE_Maj),
		fTotal = SUM(fTotal),
		BeneficiaireChq = MAX(BeneficiaireChq),
		BLastName,
		SLastName,
		BFirstName,
		SFirstName
		,TypePmt = MIN(TypePmt)
		,DDDNo = MAX(DDDNo)
        ,Cohorte
	into #tblFinal
	FROM #TMPBourse
	--where conventionNo = 'I-20080521001'
	GROUP BY
		TypeChq,
		ScholarshipID,
		iCheckHistoryID, -- POUR COMPATIBILITÉ AVEC ANCIENNE SP
		iCheckStatusID, -- POUR COMPATIBILITÉ AVEC ANCIENNE SP
		PlanDesc,
		PlanType,
		--OperID, -- glpi 4523
		BourseNo,
		conventionNo,
		Beneficiaire,
		Souscripteur,
		UnitQty,
		BLastName,
		SLastName,
		BFirstName,
		SFirstName,
        Cohorte
	ORDER BY 
		PlanDesc,
		BourseNo,
		case when @cOrder = 'B' then BLastName else SLastName end,
		case when @cOrder = 'B' then BFirstName else SFirstName end,
		ConventionNo

	SELECT 
		IDBenefEnDateDuPAE = xb.iID_Nouveau_Beneficiaire,
		f.*,
		BenefLorsDuPAE = benChq.lastname + ', ' +	benChq.firstname 
				+ case when dc.OperID is not null then '->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end
	from 
		#tblFinal f
		JOIN dbo.Un_Convention c on c.ConventionNo = f.ConventionNo
			-- pour retrouver le bénéficiaire de la convention en date du PAE
		JOIN (
			select
				iID_Convention, 
				iID_Changement_Beneficiaire,
				iID_Nouveau_Beneficiaire,
				StartDate, EndDate = min(EndDate)
			from (	
				select
					adebut.iID_Nouveau_Beneficiaire,
					aDebut.iID_Changement_Beneficiaire,aDebut.iID_Convention,StartDate = aDebut.dtDate_Changement_Beneficiaire, EndDate = aFin.dtDate_Changement_Beneficiaire
				from 
					tblCONV_ChangementsBeneficiaire aDebut
					left join tblCONV_ChangementsBeneficiaire aFin on aDebut.iID_Convention = afin.iID_Convention and aFin.dtDate_Changement_Beneficiaire >= aDebut.dtDate_Changement_Beneficiaire  and aFin.iID_Changement_Beneficiaire > aDebut.iID_Changement_Beneficiaire 
				) VV
			group by 
				iID_Convention,iID_Changement_Beneficiaire,
				StartDate,iID_Nouveau_Beneficiaire
			) xb on c.conventionid = xb.iID_Convention 
			AND LEFT(CONVERT(VARCHAR, isnull(xb.StartDate,getdate()), 120), 10) <= LEFT(CONVERT(VARCHAR, isnull(f.PAEOperDate,getdate()), 120), 10)  
			AND LEFT(CONVERT(VARCHAR, isnull(xb.EndDate,'3000-01-01'), 120), 10) > LEFT(CONVERT(VARCHAR, isnull(f.PAEOperDate,getdate()), 120), 10)  
		JOIN dbo.mo_human benChq on xb.iID_Nouveau_Beneficiaire = benChq.humanid

		left join (
			select o.OperID, p.iPayeeID
			from un_oper o
			join (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				join Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				join CHQ_Operation co on co.iOperationID = ol.iOperationID
				join CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				AND O.Operdate between @StartDate and @EndDate
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			join CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
			) dc on dc.OperID = f.OperID and dc.iPayeeID <> xb.iID_Nouveau_Beneficiaire -- on sort juste ceux qui sont différent
		left JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID

	ORDER BY 
		PlanDesc,
		BourseNo,
		case when @cOrder = 'B' then BLastName else SLastName end,
		case when @cOrder = 'B' then BFirstName else SFirstName end,
		ConventionNo		
    */
END