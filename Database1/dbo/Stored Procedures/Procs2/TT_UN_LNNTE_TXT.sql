
/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_LNNTE_TXT
Description         :	Procédure créant un fichier .txt de tous les numéros de téléphones des bénéficiaires et souscripteurs
						des conventions actives
Note                :	2008-10-15	Pierre-Luc Simard	Création
					2008-11-14  Donald Huppé		Ajout des champs REPR, DIR, Actif
					2009-04-14	Pierre-Luc Simard	Téléphone bureau retiré de la liste
					2009-07-09	Pierre-Luc Simard	Ajout des adresses courriels des représentants et directeurs (@universitas.qc.ca)
					2010-06-18	Pierre-Luc Simard	Ajout des informations sur les résiliations et RI
					2010-07-05	Donald Huppé		Modifications pour obtenir les numéros de téléphones des conventions sans groupe d'unité
													simplification pour enlever les UNION pour chaque type de numéro de tel.
													Mis en commentaire les résiliations et RI dans le fichier de sortie (dans la commande xp_Cmdshell) en attendant plus de détails de Charles Meilleur
					2010-10-08	Pierre-Luc simard	Ajout du champ RepCode, mise en commentaire des noms et adresses courriel et exclusion des clients sans représentant
					2012-11-16	Donald Huppé		GLPI 4825
					2013-07-05	Donald Huppé		glpi 9585 : si le client est TRI alors on met la date de vigeur de la collective originale et on ne met pas de date de résiliation
                         2017-01-10     Steeve Picard       Renommage de l'index sur la table «TmpMO_Adr» pour respecter le standard
						
					EXEC TT_UN_LNNTE_TXT '\\gestas2\dhuppe$\temp\testLNNTE.csv'
						
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_LNNTE_TXT] ( 
	@FileName varchar(100)) 
AS 
BEGIN
    DECLARE @str VARCHAR(1000) 
    DECLARE @DataBaseName VARCHAR(255) 
    
    SELECT @DataBaseName = DB_NAME()
    
	IF EXISTS (SELECT Name FROM SYSOBJECTS WHERE Name = 'TmpMO_Adr')
	BEGIN
	DROP TABLE TmpMO_Adr
	END
	
	IF EXISTS (SELECT Name FROM SYSOBJECTS WHERE Name = 'tTel')
	BEGIN
	DROP TABLE tTel
	END

	CREATE TABLE tTel (
		Autom int identity(1,1),
		Tel VARCHAR(27),
		RepCode VARCHAR(5),
		ACTIF varchar(1),
		--Date_Vigueur_TRI VARCHAR(10),
		Date_Vigueur VARCHAR(10),
		Resiliation VARCHAR(10),
		Remb_integral VARCHAR(10),
		Fin_Regime VARCHAR(10),
		
		Date24ans VARCHAR(10),
		Date25ans VARCHAR(10),
		--DateFinRegime VARCHAR(10),
		LastDateBrs3 VARCHAR(10),
		
		REP_AU_DOSSIER int
		)

	CREATE TABLE TmpMO_Adr (
		AdrId Int,
		Phone VARCHAR(27)
		,Email varchar(250) 
		)

--SELECT getdate()
	--drop table TmpMO_Adr
	
	INSERT INTO TmpMO_Adr
	SELECT DISTINCT adrid, Phone = phone1, Email
	FROM dbo.Mo_Adr 
	WHERE Phone1 IS NOT NULL AND LEN(Phone1) = 10 AND LEFT(Phone1,1) <> '0' 

	INSERT INTO TmpMO_Adr
	SELECT adrid, Phone = Fax, Email
	FROM dbo.Mo_Adr 
	WHERE Fax IS NOT NULL AND LEN(Fax) = 10 AND LEFT(Fax,1) <> '0' 

	INSERT INTO TmpMO_Adr
	SELECT adrid, Phone = Mobile, Email
	FROM dbo.Mo_Adr 
	WHERE Mobile IS NOT NULL AND LEN(Mobile) = 10 AND LEFT(Mobile,1) <> '0' 

	INSERT INTO TmpMO_Adr
	SELECT adrid, Phone = WattLine, Email
	FROM dbo.Mo_Adr 
	WHERE WattLine IS NOT NULL AND LEN(WattLine) = 10 AND LEFT(WattLine,1) <> '0' 

	INSERT INTO TmpMO_Adr
	SELECT adrid, Phone = OtherTel, Email
	FROM dbo.Mo_Adr 
	WHERE OtherTel IS NOT NULL AND LEN(OtherTel) = 10 AND LEFT(OtherTel,1) <> '0' 

	INSERT INTO TmpMO_Adr
	SELECT adrid, Phone = Pager, Email
	FROM dbo.Mo_Adr 
	WHERE Pager IS NOT NULL AND LEN(Pager) = 10 AND LEFT(Pager,1) <> '0' 

	CREATE INDEX IX_TmpMO_Adr_AdrId on TmpMO_Adr(adrID)

--SELECT getdate()

	INSERT INTO tTel (
			tel,
			RepCode,
			actif,
			--Date_Vigueur_TRI,
			Date_Vigueur,
			Resiliation,
			Remb_integral,
			Fin_Regime,
			
			Date24ans,
			Date25ans,
			--DateFinRegime,
			LastDateBrs3,
			
			REP_AU_DOSSIER)

		-- Tous les types de téléphone

		SELECT DISTINCT 
			Tel =	ltrim(rtrim(A.Phone)) ,
			Repcode = R.RepCode,
			Actif = cast(CASE WHEN DV.phone IS NOT NULL or DV_TRI.Phone IS NOT NULL THEN 1 ELSE 0 END as varchar(1)),--glpi 9585
			--Date_Vigueur_TRI = LEFT(CONVERT(VARCHAR, Date_Vigueur_TRI, 120), 10),
			Date_Vigueur = 
					CASE -- prendre la plus petite de Date_Vigueur et Date_Vigueur_TRI
					WHEN Date_Vigueur IS NOT NULL or Date_Vigueur_TRI IS NOT NULL THEN 
						CASE WHEN isnull(Date_Vigueur,'3000-01-01') < isnull(Date_Vigueur_TRI,'3000-01-01') then LEFT(CONVERT(VARCHAR, Date_Vigueur, 120), 10)  ELSE LEFT(CONVERT(VARCHAR, Date_Vigueur_TRI, 120), 10)  end
					ELSE 
						cast('0000-00-00' AS varchar(10)) 
					END,

			Resiliation = 
					-- Dernière date de Resiliation si 
							--aucun gr d'unité en épargne 
							--Resiliation est plus récent de fin de régime
					CASE 
					WHEN 
						DateResil IS NOT NULL  -- on a une date de résil
						and (Date_Vigueur IS NULL AND Remb_integral IS NULL AND Date_Vigueur_TRI IS NULL) -- aucun gr d'unité ouvert
						AND DateResil > isnull(Date24ans,'1900-01-01')
						and DateResil > isnull(Date25ans,'1900-01-01')
						and DateResil > isnull(LastDateBrs3,'1900-01-01')
					THEN 
						LEFT(CONVERT(VARCHAR, DateResil, 120), 10)
					ELSE  
						cast('0000-00-00' AS varchar(10))
					end,
			
			Remb_integral = 
					CASE 
					WHEN 
						Remb_integral IS NOT NULL -- on a une date de RI
						and Date_Vigueur IS NULL -- on a aucune convention en épargne sans RI
					THEN
						LEFT(CONVERT(VARCHAR, Remb_integral, 120), 10)
					ELSE 
						cast('0000-00-00' AS varchar(10))
					END,
							
			Fin_Regime = 
					-- Dernière date de fin de régime si 
							--aucun gr d'unité en épargne 
							--fin de régime est plus récent de résiliation
					CASE 
					WHEN 
						(Date_Vigueur IS NULL AND Remb_integral IS NULL)  -- aucun gr d'unité ouvert
					THEN
						CASE
						WHEN 
							isnull(Date24ans,'1900-01-01') > isnull(DateResil,'1900-01-01')
							AND isnull(Date24ans,'1900-01-01') > isnull(Date25ans,'1900-01-01')
							AND isnull(Date24ans,'1900-01-01') > isnull(LastDateBrs3,'1900-01-01')
						THEN LEFT(CONVERT(VARCHAR, Date24ans, 120), 10)
						
						WHEN 
							isnull(Date25ans,'1900-01-01') > isnull(DateResil,'1900-01-01')
							AND isnull(Date25ans,'1900-01-01') > isnull(Date24ans,'1900-01-01')
							AND isnull(Date25ans,'1900-01-01') > isnull(LastDateBrs3,'1900-01-01')
						THEN LEFT(CONVERT(VARCHAR, Date25ans, 120), 10)
						
						WHEN 
							isnull(LastDateBrs3,'1900-01-01') > isnull(DateResil,'1900-01-01')
							AND isnull(LastDateBrs3,'1900-01-01') > isnull(Date24ans,'1900-01-01')
							AND isnull(LastDateBrs3,'1900-01-01') > isnull(Date25ans,'1900-01-01')
						THEN LEFT(CONVERT(VARCHAR, LastDateBrs3, 120), 10)
						ELSE 
							cast('0000-00-00' AS varchar(10))
						end	
					ELSE
						cast('0000-00-00' AS varchar(10))
					END,

			Date24ans = LEFT(CONVERT(VARCHAR, Date24ans, 120), 10),
			Date25ans = LEFT(CONVERT(VARCHAR, Date25ans, 120), 10),
			--DateFinRegime = LEFT(CONVERT(VARCHAR, DateFinRegime, 120), 10),
			LastDateBrs3 = LEFT(CONVERT(VARCHAR, LastDateBrs3, 120), 10),
			
			REP_AU_DOSSIER = CASE WHEN R.RepID <> ut.Repid THEN 0 else 1 end

		FROM TmpMO_Adr A 
		JOIN dbo.Mo_Human H ON H.AdrID = A.AdrID
		JOIN dbo.Un_Convention C ON C.SubscriberID = H.HumanID
		JOIN dbo.Un_Subscriber SUB ON C.SubscriberID = SUB.SubscriberID

		JOIN dbo.Mo_Human REP ON SUB.repID = REP.HumanID
		JOIN Un_Rep R ON R.RepID = REP.HumanID

		-- Retrouver par no tel, le Rep selon le dernier gr d'unité vendu max(unitid) et MAX(InForceDate)---------
		JOIN TmpMO_Adr AT ON AT.phone = A.phone
		JOIN dbo.Mo_Human HT ON HT.AdrID = AT.AdrID
		JOIN dbo.Un_Convention CT ON CT.SubscriberID = HT.HumanID
		JOIN dbo.Un_Unit UT ON UT.conventionID = C.conventionID
		JOIN 
			( -- MAX(UnitID) par maxInforceDate
			SELECT 
				MAXUnitID = MAX(UU.UnitID),
				Tel = ADU.phone
			FROM 
				( -- MAX(InForceDate) par Tel
				SELECT
					tel = AD.phone,
					maxInforceDate = MAX(U.InForceDate)
				FROM dbo.Un_Unit U
				JOIN dbo.Un_Convention CO ON u.conventionID = CO.conventionID
				JOIN dbo.Mo_Human HU ON CO.SubscriberID = HU.HumanID
				JOIN TmpMO_Adr AD ON HU.AdrID = AD.AdrID
				LEFT JOIN tblOPER_OperationsRIO r ON r.iID_Convention_Destination = CO.conventionID AND R.bRIO_Annulee = 0 AND R.bRIO_QuiAnnule = 0
				WHERE LEN(AD.phone) = 10 AND LEFT(AD.phone,1) <> '0' 
				and r.iID_Operation_RIO is null -- la dernière convention du sousc ne doit pas être issu de RIO TRI RIM
				GROUP BY AD.phone
				) MUNIT

			JOIN dbo.Un_Unit UU ON UU.InForceDate = MUNIT.maxInforceDate
			JOIN dbo.Un_Convention COU ON UU.conventionID = COU.conventionID
			JOIN dbo.Mo_Human HUU ON COU.SubscriberID = HUU.HumanID
			JOIN TmpMO_Adr ADU ON HUU.AdrID = ADU.AdrID AND ADU.phone = MUNIT.TEL
			WHERE LEN(ADU.phone) = 10 AND LEFT(ADU.phone,1) <> '0' 
			GROUP BY ADU.phone
			) MCO ON A.phone = MCO.tel AND MCO.maxUnitID = UT.unitID
		
		LEFT JOIN ( --COL 4. DATE_VIGUEUR  des groupe d'unité en épargne SANS RI
			SELECT 
				ta.phone, 
				--Date_Vigueur = MIN(u6.dtFirstDeposit)  
				Date_Vigueur = MIN(dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C6.ConventionID))
				--DateFinRegime = max([dbo].[fnCONV_ObtenirDateFinRegime] (c6.ConventionID, 'R', NULL))
			FROM  
				Un_Convention c6
				JOIN (
					select Cs.conventionid 
					from un_conventionconventionstate cs
						join (select conventionid,startdate = max(startDate)
							from un_conventionconventionstate
							group by conventionid
							) ccs on ccs.conventionid = cs.conventionid and ccs.startdate = cs.startdate and cs.ConventionStateID <> 'FRM'
					)CSS ON C6.CONVENTIONID = CSS.CONVENTIONID
				JOIN dbo.Mo_Human HB ON c6.SubscriberID = HB.HumanID
				JOIN dbo.Mo_Adr ba ON HB.AdrID = ba.AdrID
				JOIN TmpMO_Adr ta ON ba.AdrID = ta.adrid
				JOIN dbo.Un_Unit u6 ON c6.ConventionID = u6.ConventionID AND u6.TerminatedDate IS NULL AND u6.IntReimbDate IS NULL
				LEFT JOIN tblOPER_OperationsRIO r ON r.iID_Convention_Destination = C6.conventionID AND R.bRIO_Annulee = 0 AND R.bRIO_QuiAnnule = 0 
			WHERE 
				IntReimbDate is null -- SANS RI
				and r.iID_Operation_RIO is null -- la dernière convention du sousc ne doit pas être issu de RIO TRI RIM
			GROUP by ta.phone
			) DV ON A.phone = DV.phone

		LEFT JOIN ( --COL 4. DATE_VIGUEUR  convention TRI -- glpi 9585
			SELECT 
				ta.phone, 
				
				Date_Vigueur_TRI = MIN(dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C6.ConventionID))
				
			FROM  
				Un_Convention c6
				JOIN dbo.Mo_Human HB ON c6.SubscriberID = HB.HumanID
				JOIN dbo.Mo_Adr ba ON HB.AdrID = ba.AdrID
				JOIN TmpMO_Adr ta ON ba.AdrID = ta.adrid
				JOIN tblOPER_OperationsRIO r ON r.iID_Convention_Source = C6.conventionID AND R.bRIO_Annulee = 0 AND R.bRIO_QuiAnnule = 0 and r.OperTypeID = 'TRI'
			WHERE 1=1
			GROUP by ta.phone
			) DV_TRI ON A.phone = DV_TRI.phone

		LEFT JOIN ( -- Col 6 : Remb_integral qui sont non fermé

			select ta5.phone, nbRI = count(*), Remb_integral = max(IntReimbDate)
			FROM dbo.Un_Unit un8
			JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID --AND C8.conventionno NOT LIKE 'T%' -- exclure les T issu du RIO
			JOIN (
				select Cs.conventionid 
				from un_conventionconventionstate cs
					join (select conventionid,startdate = max(startDate)
						from un_conventionconventionstate
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid and ccs.startdate = cs.startdate and cs.ConventionStateID <> 'FRM'
				)CSS ON C8.CONVENTIONID = CSS.CONVENTIONID
			JOIN dbo.Mo_Human HB ON c8.SubscriberID = HB.HumanID
			JOIN dbo.Mo_Adr ba ON HB.AdrID = ba.AdrID
			JOIN TmpMO_Adr ta5 ON ba.AdrID = ta5.adrid
			LEFT JOIN tblOPER_OperationsRIO r ON r.iID_Convention_Destination = C8.conventionID AND R.bRIO_Annulee = 0 AND R.bRIO_QuiAnnule = 0
			where 
				IntReimbDate is not null -- AVEC RI
				--AND un8.terminateddate IS null
				AND r.iID_Operation_RIO is null -- Exclure les conv issus d'un RIO TRI RIM
			group by ta5.phone

			) SRI ON A.phone = SRI.phone

		LEFT JOIN ( -- Col 5. Resiliation 
		
			select ta3.phone, nbResil = count(*), DateResil = max(terminateddate)
			FROM dbo.Un_Unit un8
			JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
			JOIN dbo.Mo_Human HB ON c8.SubscriberID = HB.HumanID
			JOIN dbo.Mo_Adr ba ON HB.AdrID = ba.AdrID
			JOIN TmpMO_Adr ta3 ON ba.AdrID = ta3.adrid
			LEFT JOIN tblOPER_OperationsRIO r ON r.iID_Convention_Source = C8.conventionID AND R.bRIO_Annulee = 0 AND R.bRIO_QuiAnnule = 0 and r.OperTypeID = 'TRI'
			where terminateddate is not null
			AND r.iID_Convention_Source IS NULL
			group by ta3.phone

			) sr ON A.phone = sr.phone

		LEFT JOIN ( -- 24 ans d'âge 
		
			select ta3.phone, 
			Date24ans = max(dateadd(dd,-1, dateadd(yy,1,  DATEADD(yy, DATEDIFF(yy,0,dateadd(yy,24,HB.birthdate)), 0) )))
			FROM dbo.Un_Unit un8
			JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
			JOIN (
				select 
					us.unitid,
					uus.startdate,
					us.UnitStateID
				from 
					Un_UnitunitState us
					join (
						select 
						unitid,
						startdate = max(startDate)
						from un_unitunitstate
						group by unitid
						) uus on uus.unitid = us.unitid 
							and uus.startdate = us.startdate 
							and us.UnitStateID in ('LAG')
					) uss ON un8.unitid = uss.unitid	
			JOIN un_scholarship s24 ON C8.conventionid = s24.conventionid and s24.scholarshipNO = 1 AND s24.ScholarshipStatusID = '24Y'
			JOIN dbo.Mo_Human HB ON c8.BeneficiaryID = HB.HumanID
			JOIN dbo.Mo_Human HS ON c8.SubscriberID = HS.HumanID
			JOIN dbo.Mo_Adr ba ON HS.AdrID = ba.AdrID
			JOIN TmpMO_Adr ta3 ON ba.AdrID = ta3.adrid
			group by ta3.phone

			) y24 ON A.phone = y24.phone

		LEFT JOIN ( -- 25 vie de régime 
		
			select ta3.phone, 
			Date25ans = CASE WHEN MAX(s25.conventionid) IS NOT NULL then max(dateadd(dd,-1, dateadd(yy,1,  DATEADD(yy, DATEDIFF(yy,0,dateadd(yy,25,un8.signaturedate)), 0) ))) ELSE NULL END
			FROM dbo.Un_Unit un8
			JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
			-- 25 ans de vie de régime
			JOIN un_scholarship s25 ON C8.conventionid = s25.conventionid and s25.scholarshipNO = 2 AND s25.ScholarshipStatusID = '25Y'
			JOIN dbo.Mo_Human HB ON c8.SubscriberID = HB.HumanID
			JOIN dbo.Mo_Adr ba ON HB.AdrID = ba.AdrID
			JOIN TmpMO_Adr ta3 ON ba.AdrID = ta3.adrid
			group by ta3.phone

			) y25 ON A.phone = y25.phone

		LEFT JOIN ( -- Bourse 3 
		
			select ta3.phone, 
			LastDateBrs3 = max(op.OperDate)
			FROM dbo.Un_Convention C8 
			join (
				select 
					Cs.conventionid ,
					ccs.startdate,
					cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
				) css on C8.conventionid = css.conventionid
			-- Info de bourse 3
			JOIN Un_Scholarship sc11 ON C8.ConventionID = sc11.ConventionID AND ((sc11.ScholarshipNo >= 1 AND C8.PlanID = 4 AND css.ConventionStateID = 'FRM') OR (sc11.ScholarshipNo = 3 AND C8.PlanID <> 4)) AND sc11.ScholarshipStatusID = 'PAD'
			JOIN Un_ScholarshipPmt Bp on Bp.ScholarshipID = sc11.ScholarshipID
			JOIN un_oper op on bp.operid = op.operid		
			JOIN dbo.Mo_Human HB ON c8.SubscriberID = HB.HumanID
			JOIN dbo.Mo_Adr ba ON HB.AdrID = ba.AdrID
			JOIN TmpMO_Adr ta3 ON ba.AdrID = ta3.adrid
			group by ta3.phone

			) brs3 ON A.phone = brs3.phone
			
		--where A.phone =  '4504121130' --'4502933270'

--return
	--SELECT getdate()
				
	-- Les conventions sans groupe d'unité
	INSERT INTO tTel (
			tel,
			RepCode,
			actif,
			--Date_Vigueur_TRI,
			Date_Vigueur,
			Resiliation,
			Remb_integral,
			Fin_Regime,
			
			Date24ans,
			Date25ans,
			--DateFinRegime,
			LastDateBrs3,
			
			REP_AU_DOSSIER)
	SELECT DISTINCT 
		Tel =	ltrim(rtrim(A.Phone)) ,
		Repcode = R.RepCode,
		Actif = 1,
		--Date_Vigueur_TRI = '0000-00-00',
		Date_Vigueur = '0000-00-00',
		Resiliation = '0000-00-00',
		Remb_integral = '0000-00-00',
		Fin_Regime = '0000-00-00',
		
		Date24ans = '0000-00-00',
		Date25ans = '0000-00-00',
		--DateFinRegime = '0000-00-00',
		LastDateBrs3 = '0000-00-00',
		
		REP_AU_DOSSIER = 1

	FROM TmpMO_Adr A 
	JOIN dbo.Mo_Human H ON H.AdrID = A.AdrID
	JOIN dbo.Un_Convention C ON C.SubscriberID = H.HumanID
	join (
		select 
			Cs.conventionid ,
			ccs.startdate,
			cs.ConventionStateID
		from 
			un_conventionconventionstate cs
			join (
				select 
				conventionid,
				startdate = max(startDate)
				from un_conventionconventionstate
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('PRP')
		) CSS ON CSS.ConventionID = C.ConventionID
	JOIN dbo.Un_Subscriber SUB ON C.SubscriberID = SUB.SubscriberID
	JOIN dbo.Mo_Human REP ON SUB.repID = REP.HumanID
	JOIN Un_Rep R ON R.RepID = REP.HumanID
	LEFT JOIN tTel t ON A.Phone = t.Tel
	LEFT JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
	WHERE 
		U.ConventionID IS null 
		and t.Tel IS NULL

	-- Dans ce dernier SQL, on enlève les doublons des Tel qui étaient dans des champs différents ex: les même tel dans dans phone1 et phone2
    --SET @str = 'Exec Master..xp_Cmdshell ''bcp "' +
    --                'SELECT t1.Tel+'''',''''+ REPR +'''',''''+ DIR +'''',''''+actif ' + 
    --                  'FROM UnivBase.dbo.tTel t1 ' +
    --                       'JOIN (select mautom = max(autom),tel ' + 
    --                               'from UnivBase.dbo.ttel ' +
    --                              'group by tel' +
    --                            ') t2 on t1.autom = t2.mautom " ' +
    --                'queryout "' + @FileName + '" -c -T -w ''' 
	
	-- Le paramètre -C 65001 permet de générer le fichier en UTF-8
	SET @str = 'Exec Master..xp_Cmdshell ''bcp "' + 
	                'SELECT t1.Tel, RepCode, actif, Date_Vigueur,Resiliation,Remb_integral ,Fin_Regime,REP_AU_DOSSIER ' +
	                  'FROM ' + @DataBaseName + '.dbo.tTel t1 '  + 
	                        'JOIN (select mautom = max(autom),tel ' +
	                                'from ' + @DataBaseName + '.dbo.ttel ' +
	                               'group by tel' +
	                             ') t2 on t1.autom = t2.mautom ' +
	                 'ORDER BY t1.Tel" ' + 
	                'queryout "' + @FileName + '" -t"," -c -T ''' ---C 65001 ''' 
	EXEC(@str) 
	
	/*
	SELECT 
		t1.Tel, 
		RepCode, 
		actif, 
		--Date_Vigueur_TRI,
		Date_Vigueur,
		Resiliation,
		Remb_integral ,
		Fin_Regime,
		
		--Date24ans,
		--Date25ans,
		--DateFinRegime,
		--LastDateBrs3,
		
		REP_AU_DOSSIER 
	FROM 
		UnivBase_donald.dbo.tTel t1 
		JOIN (select mautom = max(autom),tel from UnivBase_donald.dbo.ttel group by tel) t2 on t1.autom = t2.mautom 
	--where t1.Tel =   '4504121130' --'4502933270'
	ORDER BY t1.Tel
	*/
	--RETURN
	
END
