/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_ReleveDeFermeture
Description         :	
Valeurs de retours  :	Dataset de données

						TypeLigne : 
						20-DTL : Opération dans la période
						30-SLD : Solde de clôture à la fin de la période  
						

Note                :
	
					2015-02-18	Donald Huppé	Création 
					2018-12-04	DonaLd Huppé	JIRA PROD-12969 : Ajouter la ristourne RST dans le compte PAE

exec psCONV_ReleveDeFermeture '0812081'

DROP PROC psCONV_ReleveDeFermeture

*********************************************************************************************************************/


CREATE PROCEDURE [dbo].[psCONV_ReleveDeFermeture] (
		
		@conventionNO varchar(30)  -- '2025720'
		

	)
AS
BEGIN





	select 
		u.ConventionID, DateFRM = min(o.OperDate)
	INTO #Conv
	from 
		Un_Unit u
		join Un_Convention c on u.ConventionID = c.ConventionID 
		join Un_Cotisation ct on u.UnitID = ct.UnitID
		join Un_Oper o on ct.OperID = o.OperID
		left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
		left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
	where 
		o.OperTypeID = 'FRM' 
		AND OC1.OperSourceID IS NULL
		AND OC2.OperID IS NULL
		and c.ConventionNo = @conventionNO
	GROUP by u.ConventionID



	SELECT *
	INTO #OperTypeDESC
	FROM (
		SELECT OperTypeID = 'COT', DescFRA = 'Cotisations', DescANG = 'Contributions'
		UNION
		SELECT OperTypeID = 'SUB', DescFRA = 'Subventions reçues', DescANG = 'Grants Received'
		UNION
		SELECT OperTypeID = 'REV', DescFRA = 'Revenus accumulés', DescANG = 'Accumulated Income'
		UNION
		SELECT OperTypeID = 'RIN', DescFRA = 'Remboursement de cotisations', DescANG = 'Refund of Contributions'
		UNION
		SELECT OperTypeID = 'RIO', DescFRA = 'Transfert au contrat ', DescANG = 'Transfer to Agreement '
		UNION
		SELECT OperTypeID = 'PAE', DescFRA = 'Paiement d''aide aux études (PAE)', DescANG = 'Educational Assistance Payment (EAP)'
		UNION
		SELECT OperTypeID = 'PRA', DescFRA = 'Paiement de revenus accumulés (PRA)', DescANG = 'Accumulated Income Payment (AIP)'
		)d


	-- Info sur la convention
	SELECT

		c.ConventionNo
		,c.ConventionID
		,c.SubscriberID
		,BeneficiaryID = BeneficiaryIDEnDateDu
		,SubPrenom = hs.FirstName
		,SubNom = hs.LastName
		,LangID = hs.LangID
		,SubLongSexName = SubSex.LongSexName
		,SubShortSexName = SubSex.ShortSexName
		,SubAdresse = SubAdr.Address
		,SubVille = SubAdr.City
		,SubEtat = SubAdr.StateName
		,SubCodePostal = dbo.fn_Mo_FormatZIP( SubAdr.ZipCode,subadr.CountryID)
		,SubCountryID = SubAdr.CountryID
		,SubCountryName = cn.CountryName
		,BenPrenom = hb.FirstName
		,BenNom = hb.LastName
		,BenSex = hb.SexID
		-- Représentant, s'il est inactif alors on inscrit le nom du directeur
		,Prenom_Representant = isnull(REP.Prenom_Representant,DIR.Prenom_Directeur)
		,Nom_Representant = isnull(REP.Nom_Representant,DIR.Nom_Directeur)
		,RepTelephone = isnull(REP.RepTelephone,DIR.DirTelephone)
		,RepCourriel = isnull(REP.RepCourriel,DIR.DirCourriel)
		
		,LePlan = UPPER(CASE 
						WHEN hs.LangID = 'ENU' AND p.PlanDesc = 'Reeeflex' THEN 'Reflex'
						WHEN hs.LangID = 'ENU' AND p.PlanDesc = 'Individuel' THEN 'Individual' 
						ELSE p.PlanDesc END
						)
		,p.PlanTypeID
		,GrRegimeCode = RR.vcCode_Regroupement
		,ms.QteUnite

		,DateAdhesion = ms.SignatureDate
		,cv.DateFRM
		,PlanIND = CASE WHEN p.PlanTypeID = 'IND' THEN 1 ELSE 0 END
		,PlanCOL = CASE WHEN p.PlanTypeID = 'COL' THEN 1 ELSE 0 END
		,ConventionStateIDFin = cssFin.ConventionStateID

	INTO #ConventionRCinfo
	FROM 
		Un_Convention C
		join #Conv cv on c.ConventionID = cv.ConventionID
		JOIN Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		JOIN Mo_Human hs ON c.SubscriberID = hs.HumanID
		JOIN Mo_Sex SubSex on hs.SexID = SubSex.SexID and hs.LangID = SubSex.LangID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN (
			select 
				u.ConventionID, SignatureDate = min(u.SignatureDate), QteUnite = sum(u.UnitQty + isnull(ur1.QteUniteRES,0))
			from 
				Un_Unit u
				join Un_Convention c on u.ConventionID = c.ConventionID 
				join #Conv cv on c.ConventionID = cv.ConventionID
				left join (
					SELECT uu.UnitID, QteUniteRES = sum(ur.UnitQty)
					from Un_UnitReduction ur
					join Un_Unit uu on ur.UnitID = uu.UnitID
					join #Conv cv on uu.ConventionID = cv.ConventionID 
					where ur.ReductionDate > cv.DateFRM
					group by uu.UnitID
					) ur1 on u.UnitID = ur1.UnitID
			where 
				c.ConventionNo = @conventionNO
			GROUP by u.ConventionID
			)ms on ms.ConventionID = c.ConventionID
		--JOIN (
		--	select 
		--		u98.ConventionID, DateFRM = min(o98.OperDate)
		--	from 
		--		Un_Unit u98
		--		join Un_Convention c98 on u98.ConventionID = c98.ConventionID 
		--		join Un_Cotisation ct98 on u98.UnitID = ct98.UnitID
		--		join Un_Oper o98 on ct98.OperID = o98.OperID
		--		left join Un_OperCancelation oc1 on o98.OperID = oc1.OperSourceID
		--		left join Un_OperCancelation oc2 on o98.OperID = oc2.OperID
		--	where 
		--		o98.OperTypeID = 'FRM' 
		--		and c98.ConventionNo = @conventionNO
		--	GROUP by u98.ConventionID
		--	)FRM on FRM.ConventionID = c.ConventionID
		JOIN (
			SELECT 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			FROM 
				un_conventionconventionstate cs
				JOIN (
					SELECT 
					conventionid,
					startdate = max(startDate)
					FROM un_conventionconventionstate
					--WHERE startDate < DATEADD(d,1 ,@dtDateTo)
					GROUP BY conventionid
					) ccs ON ccs.conventionid = cs.conventionid 
						AND ccs.startdate = cs.startdate 
						--AND cs.ConventionStateID in ('REE','TRA')
		) cssFin ON C.conventionid = cssFin.conventionid


		LEFT JOIN Mo_Adr SubAdr on hs.AdrID = SubAdr.AdrID
		LEFT JOIN Mo_Country cn on SubAdr.CountryID = cn.CountryID --2016-03-03
		LEFT JOIN (
			SELECT 
				R.RepID,
				R.RepCode,
				Prenom_Representant = HR.FirstName,
				Nom_Representant = HR.LastName,
				RepTelephone = dbo.fn_Mo_FormatPhoneNo(MAX(ISNULL(tt.vcTelephone,'')),'CAN'), -- On prend le max juste pour s'assurer qu'on sort juste un tel travail actif, ce qui est théoriquement le cas
				RepCourriel = MAX(ISNULL(c.vcCourriel,''))-- On prend le max juste pour s'assurer qu'on sort juste un courriel proffessionel actif, ce qui est théoriquement le cas
			FROM Un_Rep R
			JOIN Mo_Human HR ON R.RepID = HR.HumanID
			LEFT JOIN tblGENE_Telephone tt on HR.HumanID = tt.iID_Source and GETDATE() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4
			LEFT JOIN tblGENE_Courriel c on c.iID_Source = hr.HumanID and GETDATE() BETWEEN c.dtDate_Debut and ISNULL(c.dtDate_Fin,'9999-12-31') and c.iID_Type = 2
			WHERE 
				isnull(R.BusinessEnd,'9999-12-31') > GETDATE()
				and isnull(r.BusinessStart,'9999-12-31') <= GETDATE() -- Le rep est actif
			group BY
				R.RepID,
				R.RepCode,
				HR.FirstName,
				HR.LastName	
			)REP on S.RepID = REP.RepID	
		
		LEFT JOIN ( --- Directeur du représentant
			SELECT
				RB.RepID,
				BossID = MAX(BossID)
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
						AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
					GROUP BY
							RepID
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
				WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
					AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
				GROUP BY
					RB.RepID
			)BR on BR.RepID = S.RepID
		LEFT JOIN (
			SELECT 
				R.RepID,
				R.RepCode,
				Prenom_Directeur = HR.FirstName,
				Nom_Directeur = HR.LastName,
				DirTelephone = dbo.fn_Mo_FormatPhoneNo(MAX(ISNULL(tt.vcTelephone,'')),'CAN'), -- On prend le max juste pour s'assurer qu'on sort juste un tel travail actif, ce qui est théoriquement le cas
				DirCourriel = MAX(ISNULL(c.vcCourriel,''))-- On prend le max juste pour s'assurer qu'on sort juste un courriel proffessionel actif, ce qui est théoriquement le cas
			FROM Un_Rep R
			JOIN Mo_Human HR ON R.RepID = HR.HumanID
			LEFT JOIN tblGENE_Telephone tt on HR.HumanID = tt.iID_Source and GETDATE() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4
			LEFT JOIN tblGENE_Courriel c on c.iID_Source = hr.HumanID and GETDATE() BETWEEN c.dtDate_Debut and ISNULL(c.dtDate_Fin,'9999-12-31') and c.iID_Type = 2
			group BY
				R.RepID,
				R.RepCode,
				HR.FirstName,
				HR.LastName	
			)DIR on DIR.RepID = BR.BossID

		LEFT JOIN
			(
			SELECT rc.ConventionID, BeneficiaryIDEnDateDu = CB.iID_Nouveau_Beneficiaire
			FROM tblCONV_ChangementsBeneficiaire CB
			JOIN #Conv rc ON CB.iID_Convention = rc.ConventionID
			WHERE CB.dtDate_Changement_Beneficiaire = (SELECT MAX(CB2.dtDate_Changement_Beneficiaire)
													 FROM tblCONV_ChangementsBeneficiaire CB2
													 WHERE CB2.iID_Convention = CB.iID_Convention
														AND CB2.dtDate_Changement_Beneficiaire <= rc.DateFRM)
			)benef on benef.ConventionID = c.ConventionID
		LEFT JOIN Mo_Human hb ON benef.BeneficiaryIDEnDateDu = hb.HumanID


		WHERE c.ConventionNo = @conventionNO
	





		select 
			CI.*
			,OPER.*
			,Total = ISNULL(OPER.Epargne,0) + ISNULL(OPER.Frais,0) + ISNULL(OPER.SCEE,0) + ISNULL(OPER.BEC,0) + ISNULL(OPER.IQEE,0) + ISNULL(OPER.Revenu,0) + ISNULL(OPER.ComptePAE,0) + ISNULL(OPER.Retenu,0)
			,OperDesc = case when ci.langID = 'ENU' then OD.DescANG ELSE OD.DescFRA end + case when oper.OperTypeID in ('RIO','RIM') THEN OPER.ConvDestRIO ELSE '' END
		FROM #ConventionRCinfo CI
		LEFT JOIN (


			SELECT 
				TypeLigne = '20-DTL'
				,OperID = 0
				,OperTypeID = 'COT'
				,SequenceOper = 5
				,OperDate = NULL
				,Frais = sum(ct.Fee)
				,Epargne = sum(ct.Cotisation)
				,SCEE = 0
				,BEC = 0
				,IQEE = 0
				,Revenu = 0
				,ComptePAE = 0
				,Retenu = 0
				,ConvDestRIO = NULL
			FROM 
				Un_Convention c
				JOIN Un_Plan P ON C.PlanID = P.PlanID
				JOIN #Conv CV on CV.ConventionID = C.ConventionID
				JOIN Un_Unit U ON c.ConventionID = U.ConventionID
				JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
				JOIN un_oper o ON ct.OperID = o.OperID
				LEFT JOIN Un_OperCancelation OC1 on O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 on O.OperID = OC2.OperID
				LEFT JOIN (
					SELECT o.OperID
					from Un_Oper o
					JOIN Un_Cotisation ct on ct.OperID = o.OperID
					JOIN Un_Unit u on ct.UnitID = u.UnitID
					JOIN Un_Convention c on u.ConventionID = c.ConventionID
					JOIN #Conv CV on CV.ConventionID = C.ConventionID
					--left join Un_TFR tfr on o.OperID = tfr.OperID
					JOIN Un_OtherAccountOper oa on oa.OperID = ct.OperID
					where o.OperTypeID = 'TFR'
					) MontantTransfereDansCompteGUI on o.OperID = MontantTransfereDansCompteGUI.OperID
			WHERE 
				o.OperTypeID not in ('RIN','RET')
				AND (O.OperTypeID NOT IN ('RIO','RIM','TRI') OR P.PlanTypeID = 'IND' )
				AND MontantTransfereDansCompteGUI.OperID is null
				--AND OC1.OperSourceID IS NULL
				--AND OC2.OperID IS NULL
			HAVING sum(ct.Fee) <> 0 OR sum(ct.Cotisation) <> 0

			UNION ALL

			SELECT 
				TypeLigne = '20-DTL'
				,OperID = 0
				,OperTypeID = 'SUB'
				,SequenceOper = 10
				,OperDate = null
				,Frais = 0
				,Epargne = 0
				,SCEE = SUM(SCEE)
				,BEC = SUM(BEC)
				,IQEE = SUM(IQEE)
				,Revenu = 0
				,ComptePAE = 0
				,Retenu = 0
				,ConvDestRIO = NULL
			FROM (

				select
					TypeLigne = NULL
					,OperID = NULL
					,OperTypeID = NULL
					,SequenceOper = NULL
					,OperDate = null
					,Frais = 0
					,Epargne = 0
					,SCEE = SUM(CE.fCESG + CE.fACESG)
					,BEC = SUM(CE.fCLB)
					,IQEE = 0
					,Revenu = 0
					,ComptePAE = 0
					,Retenu = 0
					,ConvDestRIO = NULL
				FROM 
					Un_Convention c
					JOIN Un_Plan P ON C.PlanID = P.PlanID
					JOIN #Conv CV on CV.ConventionID = C.ConventionID
					JOIN Un_CESP CE ON C.ConventionID = CE.ConventionID
					JOIN Un_Oper O ON CE.OperID = O.OperID
				WHERE 
					O.OperTypeID NOT IN ('PAE','AVC')
					AND (O.OperTypeID NOT IN ('RIO','RIM','TRI') OR P.PlanTypeID = 'IND' )
				HAVING SUM(CE.fCESG + CE.fACESG) <> 0 OR SUM(CE.fCLB) <> 0

				UNION ALL

				SELECT 
					TypeLigne = NULL
					,OperID = NULL
					,OperTypeID = NULL
					,SequenceOper = NULL
					,OperDate = null
					,Frais = 0
					,Epargne = 0		
					,SCEE = 0
					,BEC = 0
					,IQEE = SUM(CASE WHEN  CharIndex(CO.ConventionOperTypeID, 'CBQ,MMQ', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END)
					,Revenu = 0
					,ComptePAE = 0
					,Retenu = 0
					,ConvDestRIO = NULL
				FROM 
					Un_Oper O
					JOIN Un_ConventionOper CO ON O.OperID = CO.OperID
					JOIN #Conv CV ON CO.ConventionID = CV.ConventionID
					JOIN Un_Convention C ON CO.ConventionID = C.ConventionID
					JOIN Un_Plan P ON C.PlanID = P.PlanID
				WHERE 
					O.OperTypeID NOT IN ('PAE','AVC')
					AND (O.OperTypeID NOT IN ('RIO','RIM','TRI') OR P.PlanTypeID = 'IND' )			
				HAVING SUM(CASE WHEN  CharIndex(CO.ConventionOperTypeID, 'CBQ,MMQ', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END) <> 0
				)SUB
			HAVING SUM(SCEE) <> 0 or SUM(BEC) <> 0 or SUM(IQEE) <> 0


			UNION ALL

			select
				TypeLigne = '20-DTL'
				,OperID = 0
				,OperTypeID = 'REV'
				,SequenceOper = 15
				,OperDate = null
				,Frais = 0
				,Epargne = 0
				,SCEE = 0
				,BEC = 0
				,IQEE = 0
				,Revenu = SUM(co.ConventionOperAmount)
				,ComptePAE = 0
				,Retenu = 0
				,ConvDestRIO = NULL
			FROM 
				Un_Convention c
				JOIN Un_Plan P ON C.PlanID = P.PlanID
				JOIN #Conv CV on CV.ConventionID = C.ConventionID
				JOIN Un_ConventionOper co on c.ConventionID = co.ConventionID
				JOIN un_oper o ON co.operID = o.OperID
			where 
				co.ConventionOperTypeID in ( 'IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI')
				AND o.OperTypeID NOT in ('PAE','PRA','AVC')
				AND (O.OperTypeID NOT IN ('RIO','RIM','TRI') OR P.PlanTypeID = 'IND' )
			HAVING SUM(co.ConventionOperAmount) <> 0

			UNION ALL

			SELECT 
				TypeLigne = '20-DTL',
				OperID = NULL -- O.OperID
				,OperTypeID = 'RIN' --O.OperTypeID -- vu qu'on inclut le RET dans les remboursement, je force RIN poru qu'on ait le même Label d'opération
				,SequenceOper = 20
				,OperDate = cast(O.OperDate as date)
				,Frais = SUM(ct.Fee)
				,Epargne = SUM(ct.Cotisation)
				,SCEE = 0
				,BEC = 0
				,IQEE = 0
				,Revenu = 0
				,ComptePAE = 0
				,Retenu = 0
				,ConvDestRIO = NULL
			FROM 
				Un_Convention c
				JOIN Un_Plan P ON C.PlanID = P.PlanID
				JOIN #Conv CV on CV.ConventionID = C.ConventionID
				JOIN Un_Unit U ON c.ConventionID = U.ConventionID
				JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
				JOIN un_oper o ON ct.OperID = o.OperID
				LEFT JOIN Un_OperCancelation OC1 on O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 on O.OperID = OC2.OperID
			WHERE o.OperTypeID in ('RIN','RET')
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
			GROUP BY cast(O.OperDate as date)

			UNION ALL


			select 
				
				TypeLigne
				,OperID = min(OperID)
				,OperTypeID -- RIO
				,SequenceOper = 20
				,OperDate = min(OperDate)
				,Frais = sum(Frais) 
				,Epargne = sum(Epargne)
				,SCEE = sum(SCEE)
				,BEC = sum(BEC)
				,IQEE = sum(IQEE)
				,Revenu = sum(Revenu)
				,ComptePAE = 0
				,Retenu = 0
				,ConvDestRIO
				
			from (


				SELECT 
					TypeLigne = '20-DTL',
					O.OperID
					,OperTypeID = 'RIO' -- O.OperTypeID -- on force 'RIO' car c'Est jsute pour avoir la description du transfert vers l'IND
					,OperDate --= case when ct.Cotisation <> 0 then O.OperDate else null END
					,Frais = ct.Fee 
					,Epargne = ct.Cotisation 
					,SCEE = 0
					,BEC = 0
					,IQEE = 0
					,Revenu = 0
					,ComptePAE = 0
					,Retenu = 0
					,ConvDestRIO = CRIO.ConventionNo
				FROM 
					Un_Convention c
					JOIN Un_Plan P ON C.PlanID = P.PlanID
					JOIN #Conv CV on CV.ConventionID = C.ConventionID
					JOIN Un_Unit U ON c.ConventionID = U.ConventionID
					JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
					JOIN un_oper o ON ct.OperID = o.OperID
					JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Oper_RIO = O.OperID AND RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
					JOIN Un_Convention CRIO ON CRIO.ConventionID = RIO.iID_Convention_Destination
					LEFT JOIN Un_OperCancelation OC1 on O.OperID = OC1.OperSourceID
					LEFT JOIN Un_OperCancelation OC2 on O.OperID = OC2.OperID
				WHERE o.OperTypeID in ('RIO','RIM','TRI')
					AND P.PlanTypeID = 'COL'
					--AND OC1.OperSourceID IS NULL -- on se fie à : RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
					--AND OC2.OperID IS NULL

				UNION ALL

				SELECT 
					TypeLigne = '20-DTL',
					OperID = 0
					,OperTypeID = 'RIO' -- O.OperTypeID -- on force 'RIO' car c'Est jsute pour avoir la description du transfert vers l'IND
					,OperDate --= NULL
					,Frais = 0 
					,Epargne = 0 
					,SCEE = SUM(CE.fCESG + CE.fACESG)
					,BEC = SUM(CE.fCLB)
					,IQEE = 0
					,Revenu = 0
					,ComptePAE = 0
					,Retenu = 0
					,ConvDestRIO = CRIO.ConventionNo
				FROM 
					Un_Convention c
					JOIN Un_Plan P ON C.PlanID = P.PlanID
					JOIN #Conv CV on CV.ConventionID = C.ConventionID
					JOIN Un_CESP CE ON C.ConventionID = CE.ConventionID
					JOIN un_oper o ON CE.OperID = o.OperID
					JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Oper_RIO = O.OperID AND RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
					JOIN Un_Convention CRIO ON CRIO.ConventionID = RIO.iID_Convention_Destination
					LEFT JOIN Un_OperCancelation OC1 on O.OperID = OC1.OperSourceID
					LEFT JOIN Un_OperCancelation OC2 on O.OperID = OC2.OperID
				WHERE o.OperTypeID in ('RIO','RIM','TRI')
					AND P.PlanTypeID = 'COL'
					--AND OC1.OperSourceID IS NULL -- on se fie à : RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
					--AND OC2.OperID IS NULL
				GROUP BY 
					O.OperID
					,O.OperTypeID
					,O.OperDate
					,CRIO.ConventionNo

				UNION ALL

				SELECT 
					TypeLigne = '20-DTL',
					OperID = 0
					,OperTypeID = 'RIO' -- O.OperTypeID -- on force 'RIO' car c'Est jsute pour avoir la description du transfert vers l'IND
					,OperDate --= NULL
					,Frais = 0 
					,Epargne = 0 
					,SCEE = 0
					,BEC = 0
					,IQEE = CASE WHEN CO.ConventionOperTypeID IN ('CBQ','MMQ') THEN CO.ConventionOperAmount ELSE 0 END
					,Revenu = CASE WHEN CO.ConventionOperTypeID IN ( 'IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI') THEN CO.ConventionOperAmount ELSE 0 END
					,ComptePAE = 0
					,Retenu = 0
					,ConvDestRIO = CRIO.ConventionNo
				FROM 
					Un_Convention c
					JOIN Un_Plan P ON C.PlanID = P.PlanID
					JOIN #Conv CV on CV.ConventionID = C.ConventionID
					JOIN Un_ConventionOper CO ON CO.ConventionID = c.ConventionID
					JOIN un_oper O ON CO.OperID = O.OperID
					JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Oper_RIO = O.OperID AND RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
					JOIN Un_Convention CRIO ON CRIO.ConventionID = RIO.iID_Convention_Destination
					LEFT JOIN Un_OperCancelation OC1 on O.OperID = OC1.OperSourceID
					LEFT JOIN Un_OperCancelation OC2 on O.OperID = OC2.OperID
				WHERE o.OperTypeID in ('RIO','RIM','TRI')
					AND P.PlanTypeID = 'COL'
					--AND OC1.OperSourceID IS NULL -- on se fie à : RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
					--AND OC2.OperID IS NULL

				) AllRIO
			group BY

				TypeLigne
				,OperTypeID
				,ConvDestRIO
			HAVING
				SUM(Frais) <> 0 OR SUM(Epargne) <> 0 OR SUM(SCEE) <> 0 OR SUM(BEC) <> 0 OR SUM(IQEE) <> 0 OR SUM(Revenu) <> 0


			UNION ALL

			SELECT 
				TypeLigne = '20-DTL',
				O.OperID
				,OperTypeID = 'PAE' --O.OperTypeID
				,SequenceOper = 25
				,O.OperDate
				,Frais = 0
				,Epargne = 0		
				,SCEE = ISNULL(SCEE.SCEE,0)
				,BEC = ISNULL(SCEE.BEC,0)
				,IQEE = SUM(CASE WHEN  CharIndex(CO.ConventionOperTypeID, 'CBQ,MMQ', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END) 
				,Revenu = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IBC,ICQ,III,IIQ,IMQ,INS,IS+,IST,INM,ITR,MIM,IQI', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END) 
				,ComptePAE = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'BRS,AVC,RST', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END) 
				,Retenu = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'RTN', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END) 
				,ConvDestRIO = NULL
			FROM 
				Un_Scholarship S
				JOIN #Conv CV ON CV.ConventionID = S.ConventionID
				JOIN Un_ScholarshipPmt SP on S.ScholarshipID = SP.ScholarshipID
				JOIN Un_Oper O ON SP.OperID = O.OperID
				LEFT JOIN Un_ConventionOper CO ON O.OperID = CO.OperID
				LEFT JOIN (
					SELECT CE.OperID, SCEE = SUM(CE.fCESG + CE.fACESG), BEC = SUM(CE.fCLB)
					FROM Un_CESP CE
					JOIN #Conv CV ON CV.ConventionID = CE.ConventionID
					GROUP BY CE.OperID
					)SCEE ON SCEE.OperID = O.OperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
			WHERE 
				O.OperTypeID in ( 'PAE','AVC')
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
			GROUP BY
				O.OperID
				--,O.OperTypeID
				,O.OperDate
				,SCEE.SCEE
				,SCEE.BEC

			UNION ALL

			SELECT 
				TypeLigne = '20-DTL',
				O.OperID
				,O.OperTypeID
				,SequenceOper = 30
				,O.OperDate
				,Frais = 0
				,Epargne = 0
				,SCEE = 0
				,BEC = 0
				,IQEE = 0
				,Revenu = SUM(CASE WHEN CO.ConventionOperTypeID <> 'RTN' THEN CO.ConventionOperAmount ELSE 0 END) 
				,ComptePAE = 0
				,Retenu = SUM(CASE WHEN CO.ConventionOperTypeID = 'RTN' THEN CO.ConventionOperAmount ELSE 0 END)
				,ConvDestRIO = NULL
			FROM Un_Oper O
				JOIN Un_ConventionOper CO on O.OperID = CO.OperID
				JOIN #Conv CV on CO.ConventionID = CV.ConventionID
				LEFT JOIN Un_OperCancelation OC1 on O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 on O.OperID = OC2.OperID
			WHERE 
				O.OperTypeID = 'PRA'
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
			GROUP by	
				O.OperID
				,O.OperTypeID
				,O.OperDate



			UNION ALL


			SELECT 
				TypeLigne = '30-SLD'
				,OperID = 0
				,OperTypeID = ''
				,SequenceOper = 100
				,OperDate
				,Frais = SUM(Frais)
				,Epargne = SUM(Epargne)	
				,SCEE = SUM(SCEE)
				,BEC = SUM(BEC)
				,IQEE = SUM(IQEE)
				,Revenu = SUM(Revenu)
				,ComptePAE = SUM(ComptePAE)
				,Retenu = SUM(Retenu)
				,ConvDestRIO = NULL
			FROM (


				SELECT 
					TypeLigne = NULL
					,OperID = NULL
					,OperTypeID = NULL
					,SequenceOper = NULL
					,OperDate = CV.DateFRM
					,Frais = sum(ct.Fee) 
					,Epargne = sum(ct.Cotisation)
					,SCEE = 0
					,BEC = 0
					,IQEE = 0
					,Revenu = 0
					,ComptePAE = 0
					,Retenu = 0
					,ConvDestRIO = NULL
				FROM 
					Un_Convention c
					JOIN Un_Plan P ON C.PlanID = P.PlanID
					JOIN #Conv CV on CV.ConventionID = C.ConventionID
					JOIN Un_Unit U ON c.ConventionID = U.ConventionID
					JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
					JOIN un_oper o ON ct.OperID = o.OperID
					LEFT JOIN (
						SELECT o.OperID
						from Un_Oper o
						JOIN Un_Cotisation ct on ct.OperID = o.OperID
						JOIN Un_Unit u on ct.UnitID = u.UnitID
						JOIN Un_Convention c on u.ConventionID = c.ConventionID
						JOIN #Conv CV on CV.ConventionID = C.ConventionID
						--left join Un_TFR tfr on o.OperID = tfr.OperID
						JOIN Un_OtherAccountOper oa on oa.OperID = ct.OperID
						where o.OperTypeID = 'TFR'
						) MontantTransfereDansCompteGUI on o.OperID = MontantTransfereDansCompteGUI.OperID
				WHERE O.OperDate <= CV.DateFRM
					AND MontantTransfereDansCompteGUI.OperID IS NULL
				GROUP BY CV.DateFRM

				UNION ALL

				SELECT 
					TypeLigne = NULL
					,OperID = NULL
					,OperTypeID = NULL
					,SequenceOper = NULL
					,OperDate = CV.DateFRM
					,Frais = 0
					,Epargne = 0		
					,SCEE = 0
					,BEC = 0
					,IQEE = SUM(CASE WHEN  CharIndex(CO.ConventionOperTypeID, 'CBQ,MMQ', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END)
					,Revenu = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IBC,ICQ,III,IIQ,IMQ,INS,IS+,IST,INM,ITR,MIM,IQI', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END)
					,ComptePAE = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'BRS,AVC,RTN,RST', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END)
					,Retenu = 0
					,ConvDestRIO = NULL
				FROM 
					Un_Oper O
					JOIN Un_ConventionOper CO ON O.OperID = CO.OperID
					JOIN #Conv CV ON CO.ConventionID = CV.ConventionID
				WHERE O.OperDate <= CV.DateFRM
				GROUP BY CV.DateFRM

				UNION ALL

				select
					TypeLigne = NULL
					,OperID = NULL
					,OperTypeID = NULL
					,SequenceOper = NULL
					,OperDate = CV.DateFRM
					,Frais = 0
					,Epargne = 0
					,SCEE = SUM(CE.fCESG + CE.fACESG)
					,BEC = SUM(CE.fCLB)
					,IQEE = 0
					,Revenu = 0
					,ComptePAE = 0
					,Retenu = 0
					,ConvDestRIO = NULL
				FROM 
					Un_Convention c
					JOIN Un_Plan P ON C.PlanID = P.PlanID
					JOIN #Conv CV on CV.ConventionID = C.ConventionID
					JOIN Un_CESP CE ON C.ConventionID = CE.ConventionID
					JOIN Un_Oper O ON CE.OperID = O.OperID
				WHERE O.OperDate <= CV.DateFRM
				GROUP BY CV.DateFRM
				)SLD
			GROUP BY OperDate

			)OPER ON 1=1

		left JOIN #OperTypeDESC OD ON OPER.OperTypeID = OD.OperTypeID
	

	end

