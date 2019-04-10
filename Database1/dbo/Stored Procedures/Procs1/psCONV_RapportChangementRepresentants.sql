/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportChangementRepresentants
Nom du service		: Générer un rapport de changement de représentant
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportChangementRepresentants '1950-03-04', '2014-07-11', 0, 0, 436381
								EXEC psCONV_RapportChangementRepresentants '1950-03-04', '2014-07-11', 0, 0, 149602
								EXEC psCONV_RapportChangementRepresentants '1950-03-04', '2014-07-11', 0, 0, 0
								EXEC psCONV_RapportChangementRepresentants '2013-10-30', '2015-11-30', 0, 0, 0
						
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-10-16		Maxime Martel				Création du service			
		2013-11-15		Pierre-Luc Simard			Gestion des dates et du statut de transfert
		2014-01-07		Donald Huppé				glpi 10787 : ajout de l'adresse complète et Appel
		2015-05-15		Donald Huppé				glpi 14416 : ajout du courriel
        2018-09-26      Pierre-Luc Simard           Ajout de l'audit dans la table tblGENE_AuditHumain
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportChangementRepresentants]
    @StartDate DATETIME,
    @EndDate DATETIME,
    @iRepIDOri INT = 0,
    @iRepIDNew INT = 0,
    @RepID INT = 0
AS 
BEGIN

    DECLARE @tRep TABLE (RepID INTEGER)

    IF EXISTS (-- si c'est un rep (ou un boss) 
        SELECT
            u.UserID
        FROM mo_user u
        JOIN dbo.mo_human h ON u.userid = h.humanid
        JOIN un_rep r ON h.humanid = r.repid
        WHERE u.userid = @RepID) 
        BEGIN -- on va chercher les rep du boss ou le rep tout court
            INSERT @tRep
            EXECUTE SL_UN_BossOfRep @RepID
        END
    ELSE 
        BEGIN -- sinon, on insère tous les reps
            INSERT INTO @tRep
            SELECT
                REPID
            FROM UN_REP
        END
        
    SELECT
        OldRepID = CRCS.iID_RepresentantOriginal,
        NewRepID = CRC.iID_RepresentantCible,
        CRCS.iID_Souscripteur,
        CR.dDate_Statut,
        cr.iID_UtilisateurCreation
    INTO #ChRep
    FROM tblCONV_ChangementsRepresentants CR
    JOIN tblCONV_ChangementsRepresentantsCibles CRC ON cr.iID_ChangementRepresentant = CRC.iID_ChangementRepresentant
    JOIN tblCONV_ChangementsRepresentantsCiblesSouscripteurs CRCS ON CRC.iID_ChangementRepresentantCible = CRCS.iID_ChangementRepresentantCible
    WHERE ISNULL(CRCS.iID_RepresentantOriginal, '') <> ''
        AND ISNULL(crc.iID_RepresentantCible, '') <> ''
        AND dbo.FN_CRQ_DateNoTime(CR.dDate_Statut) BETWEEN @StartDate AND @EndDate
        AND CR.iID_Statut = 3 -- Exécuté

    SELECT
        iID_UtilisateurCreation,
        UsagerTransfert = ht.FirstName + ' ' + ht.LastName,
        dDate_Statut, -- = LEFT(CONVERT(VARCHAR, logtime, 120), 10),
        ChRep.iID_Souscripteur,
        Subscriber = hs.FirstName + ' ' + hs.lastname,
        BossOri.OldBossID,
        DirOri = CASE WHEN BossOri.OldBossID IS NULL THEN 'ND' ELSE hob.FirstName + ' ' + hob.LastName END,
        ChRep.OldRepID,
        RepOri = CASE WHEN ChRep.OldRepID = -1 THEN 'ND' ELSE hor.FirstName + ' ' + hor.LastName END,
        BossNew.NewBossID,
        DirNew = hbn.FirstName + ' ' + hbn.LastName,
        ChRep.NewRepID,
        RepNew = hnr.FirstName + ' ' + hnr.LastName,
        LastSignatureDateWithNewRep = LEFT(CONVERT(VARCHAR, vnr.LastSignatureDate, 120), 10),
        DateResil = LEFT(CONVERT(VARCHAR, sr.DateResil, 120), 10),
		--DateRI = case when Ferme.DateFerme IS NULL THEN LEFT(CONVERT(VARCHAR, SRI.DateRI, 120), 10) ELSE NULL end,
        DateRI = LEFT(CONVERT(VARCHAR, SRI.DateRI, 120), 10),
        SouscActif_dtFirstDeposit = LEFT(CONVERT(VARCHAR, Sv.dtFirstDeposit, 120), 10),
        DateFerme = LEFT(CONVERT(VARCHAR, Ferme.DateFerme, 120), 10),
        adr.Address,
        phone = CASE WHEN ISNULL(adr.phone1, '') = '' THEN adr.Phone2 ELSE adr.Phone1 END,
        adr.City,
        adr.StateName,
        CodePostal =  dbo.fn_Mo_FormatZIP(adr.ZipCode,adr.countryid)
        ,Appel = ss.LongSexName
		,adr.EMail
    INTO #tpsCONV_RapportChangementRepresentants
    FROM #ChRep ChRep
    LEFT JOIN @tRep RN ON ChRep.NewRepID = RN.RepID
    LEFT JOIN @tRep RO ON ChRep.OldRepID = RO.RepID
    LEFT JOIN (
		SELECT
			RB.RepID,
			RB.StartDate,
			EndDate = ISNULL(RB.EndDate, '3000-01-01'),
			OldBossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM Un_RepBossHist RB
		JOIN (
			SELECT
				RepID,
				StartDate,
				EndDate,
				RepBossPct = MAX(RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND StartDate IS NOT NULL
			GROUP BY
				RepID,
				StartDate,
				EndDate
			) MRB ON MRB.RepID = RB.RepID
				AND MRB.RepBossPct = RB.RepBossPct
                AND MRB.StartDate = RB.StartDate
                AND ISNULL(MRB.EndDate, '3000-01-01') = ISNULL(RB.EndDate, '3000-01-01')
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate IS NOT NULL
		GROUP BY
			RB.RepID,
			RB.StartDate,
			ISNULL(RB.EndDate, '3000-01-01')
		) BossOri ON ChRep.OldRepID = BossOri.RepID
			AND ChRep.dDate_Statut BETWEEN BossOri.StartDate
            AND BossOri.EndDate
    LEFT JOIN (
		SELECT
			RB.RepID,
			RB.StartDate,
			EndDate = ISNULL(RB.EndDate, '3000-01-01'),
			NewBossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM Un_RepBossHist RB
		JOIN (
			SELECT
				RepID,
				StartDate,
				EndDate,
				RepBossPct = MAX(RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND StartDate IS NOT NULL
			GROUP BY
				RepID,
				StartDate,
				EndDate
			) MRB ON MRB.RepID = RB.RepID
				AND MRB.RepBossPct = RB.RepBossPct
                AND MRB.StartDate = RB.StartDate
                AND ISNULL(MRB.EndDate, '3000-01-01') = ISNULL(RB.EndDate, '3000-01-01')
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate IS NOT NULL
		GROUP BY
			RB.RepID,
			RB.StartDate,
			ISNULL(RB.EndDate, '3000-01-01')
		) BossNew ON ChRep.NewRepID = BossNew.RepID
			AND ChRep.dDate_Statut BETWEEN BossNew.StartDate
            AND BossNew.EndDate
	LEFT JOIN dbo.mo_human hnr ON ChRep.NewRepID = hnr.humanID
	LEFT JOIN dbo.mo_human hs ON ChRep.iID_Souscripteur = hs.humanID
	left JOIN Mo_Sex ss ON hs.SexID = ss.SexID and hs.LangID = ss.LangID
    LEFT JOIN dbo.mo_human hbn ON BossNew.NewBossID = hbn.humanID
    LEFT JOIN dbo.Mo_Human ht ON ht.HumanID = ChRep.iID_UtilisateurCreation
    LEFT JOIN dbo.mo_human hob ON BossOri.OldBossID = hob.HumanID
    LEFT JOIN dbo.mo_human hor ON ChRep.OldRepID = hor.humanID
    LEFT JOIN (-- Dernier rep ayant signé avec le souscripteur
		SELECT
			c4.SubscriberID,
            u4.RepID,
            mu.LastSignatureDate
        FROM dbo.Un_Convention c4
        JOIN dbo.Un_Unit u4 ON c4.ConventionID = u4.ConventionID
        JOIN (-- dernière signature
			SELECT
				c3.SubscriberID,
                LastSignatureDate = MAX(u3.SignatureDate)
            FROM dbo.Un_Convention c3
            JOIN dbo.Un_Unit u3 ON c3.ConventionID = u3.ConventionID
            GROUP BY
                c3.SubscriberID
            ) mu ON c4.SubscriberID = mu.SubscriberID
				AND u4.SignatureDate = mu.LastSignatureDate
		JOIN (-- dernier unitid par signature
			SELECT
                c5.SubscriberID,
                SignatureDate,
                maxunitid = MAX(u5.unitid)
            FROM dbo.Un_Convention c5
            JOIN dbo.Un_Unit u5 ON c5.ConventionID = u5.ConventionID
            GROUP BY
                c5.SubscriberID,
                SignatureDate
            ) mu2 ON c4.SubscriberID = mu2.SubscriberID
				AND mu.LastSignatureDate = mu2.SignatureDate
                AND u4.UnitID = mu2.maxunitid
		) vnr ON vnr.RepID = ChRep.NewRepID
			AND vnr.SubscriberID = ChRep.iID_Souscripteur
    LEFT JOIN (--sousc avec au moins un contrat non résilié
		SELECT
            c6.subscriberid
        FROM dbo.Un_Convention c6
        LEFT JOIN dbo.Un_Unit u6 ON c6.ConventionID = u6.ConventionID AND u6.TerminatedDate IS NOT NULL
        WHERE u6.ConventionID IS NULL
        GROUP BY c6.subscriberid
		) nr ON ChRep.iID_Souscripteur = nr.SubscriberID
    LEFT JOIN (-- sousc complètement résilié
		SELECT
            C7.SubscriberID,
            DateResil,
            NbGrUnit = COUNT(*)
        FROM dbo.Un_Unit U7
        JOIN dbo.Un_Convention C7 ON U7.ConventionID = C7.ConventionID
        JOIN (
			SELECT
				C8.SubscriberID,
				nbResil = COUNT(*),
				DateResil = MAX(terminateddate)
			FROM dbo.Un_Unit un8
            JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
			JOIN (
				SELECT
					us.unitid,
                    uus.startdate,
                    us.UnitStateID
                FROM Un_UnitunitState us
                JOIN (
					SELECT
						unitid,
                        startdate = MAX(startDate)
					FROM un_unitunitstate
					--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2010-06-01'
                    GROUP BY
						unitid
                    ) uus ON uus.unitid = us.unitid
						AND uus.startdate = us.startdate
                        AND us.UnitStateID <> 'OUT'
				) uss ON un8.UnitID = uss.UnitID
             WHERE terminateddate IS NOT NULL
            GROUP BY
				C8.SubscriberID
			) Resil ON C7.SubscriberID = Resil.SubscriberID
        GROUP BY
            C7.SubscriberID,
            Resil.nbResil,
            Resil.DateResil
        HAVING COUNT(*) = Resil.nbResil
		) sr ON ChRep.iID_Souscripteur = sr.SubscriberID
    LEFT JOIN (-- sousc complètement RI
		SELECT
			C7.SubscriberID,
            DateRI,
            NbGrUnit = COUNT(*)
        FROM dbo.Un_Unit U7
        JOIN dbo.Un_Convention C7 ON U7.ConventionID = C7.ConventionID
        JOIN (
			SELECT
				C8.SubscriberID,
                nbRI = COUNT(*),
                DateRI = MAX(IntReimbDate)
            FROM dbo.Un_Unit un8
            JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
			WHERE IntReimbDate IS NOT NULL
			GROUP BY
                C8.SubscriberID
            ) RI ON C7.SubscriberID = RI.SubscriberID
		GROUP BY
			C7.SubscriberID,
            RI.nbRI,
            RI.DateRI
        HAVING COUNT(*) = RI.nbRI
		) SRI ON ChRep.iID_Souscripteur = SRI.SubscriberID
    LEFT JOIN (--ACTIF : Souscripteur dont au moins un groupe d’unités est en vigueur et pour lequel il n’a pas reçu sont RI.
		SELECT
			c8.subscriberid,
            dtFirstDeposit = MIN(u9.dtFirstDeposit)
        FROM dbo.Un_Convention c8 --au moins un groupe d’unités est en vigueur et pour lequel il n’a pas reçu sont RI.
        JOIN dbo.Un_Unit u8 ON c8.ConventionID = u8.ConventionID
			AND u8.IntReimbDate IS NULL
            AND u8.TerminatedDate IS NULL
		--tous les groupes d'unités
        JOIN dbo.Un_Unit u9 ON c8.ConventionID = u9.ConventionID
        GROUP BY         
			c8.subscriberid
		) Sv ON ChRep.iID_Souscripteur = Sv.SubscriberID
	LEFT JOIN (-- Fermé
		SELECT
			s14.SubscriberID,
            Raison3brs = CASE WHEN b3.subscriberid IS NOT NULL THEN 1 ELSE 0 END,
            Raison35ans = CASE WHEN v35.subscriberid IS NOT NULL THEN 1 ELSE 0 END,
            RaisonOut = CASE WHEN COut.subscriberid IS NOT NULL THEN 1 ELSE 0 END,
            DateFerme = CASE WHEN ISNULL(LastDateBrs3, '1900-01-01') > ISNULL(Date35ans, '1900-01-01')
									AND ISNULL(LastDateBrs3, '1900-01-01') > ISNULL(DateOut, '1900-01-01') THEN LastDateBrs3
								WHEN ISNULL(Date35ans, '1900-01-01') > ISNULL(LastDateBrs3, '1900-01-01')
									AND ISNULL(Date35ans, '1900-01-01') > ISNULL(DateOut, '1900-01-01') THEN Date35ans
								WHEN ISNULL(DateOut, '1900-01-01') > ISNULL(LastDateBrs3, '1900-01-01')
                                  AND ISNULL(DateOut, '1900-01-01') > ISNULL(Date35ans, '1900-01-01') THEN DateOut
								END
        FROM dbo.Un_Subscriber s14
        LEFT JOIN (-- toutes les bourses 3 sont payées
			SELECT
                S.subscriberid,
                nb10.LastDateBrs3
            FROM dbo.Un_Subscriber s
            JOIN (
				SELECT
                    c10.SubscriberID,
                    NbConvNonResilie = COUNT(DISTINCT c10.ConventionID)
                FROM dbo.Un_Convention c10
                JOIN dbo.Un_Unit u10 ON c10.ConventionID = u10.ConventionID
                WHERE u10.TerminatedDate IS NULL
                GROUP BY
					c10.SubscriberID
				) nc10 ON s.SubscriberID = nc10.SubscriberID
			JOIN (
				SELECT
					c11.SubscriberID,
                    nbBrs3 = COUNT(DISTINCT c11.ConventionID),
                    LastDateBrs3 = MAX(op.OperDate)
				FROM dbo.Un_Convention c11
                JOIN (
					SELECT
						Cs.conventionid,
                        ccs.startdate,
                        cs.ConventionStateID
					FROM un_conventionconventionstate cs
					JOIN (
						SELECT
							conventionid,
                            startdate = MAX(startDate)
						FROM un_conventionconventionstate
						-- !!! mettre une journée de plus que la date demandée car on fait < ou lieu de <= !!!
						--where startDate < "Une Date Dans le temps" -- Si je veux l'état à une date précise 
                        GROUP BY                            
							conventionid
						) ccs ON ccs.conventionid = cs.conventionid
							AND ccs.startdate = cs.startdate 
							--and cs.ConventionStateID = 'FRM' -- je veux les convention qui ont cet état
					) css ON C11.conventionid = css.conventionid
				JOIN Un_Scholarship sc11 ON c11.ConventionID = sc11.ConventionID
					AND ((sc11.ScholarshipNo >= 1
							AND c11.PlanID = 4
							AND css.ConventionStateID = 'FRM')
                        OR (sc11.ScholarshipNo = 3
                            AND c11.PlanID <> 4))
					AND sc11.ScholarshipStatusID = 'PAD'
				JOIN Un_ScholarshipPmt Bp ON Bp.ScholarshipID = sc11.ScholarshipID
				JOIN un_oper op ON bp.operid = op.operid
				GROUP BY
					c11.SubscriberID
                ) nb10 ON s.SubscriberID = nb10.SubscriberID
					AND nc10.NbConvNonResilie = nb10.nbBrs3
				) b3 ON b3.subscriberid = s14.SubscriberID
        LEFT JOIN (-- 35 ans vie de régime atteint
			SELECT                
				c11.SubscriberID,
                Date35ans = CAST(YEAR(u11.signaturedate) + 35 AS VARCHAR) + '-12-31'
            FROM dbo.Un_Convention c11
            JOIN (
				SELECT
					Cs.conventionid,
                    ccs.startdate,
                    cs.ConventionStateID
				FROM un_conventionconventionstate cs
                JOIN (
					SELECT
						conventionid,
                        startdate = MAX(startDate)
					FROM un_conventionconventionstate
					--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @LaDate
                    GROUP BY
						conventionid
                    ) ccs ON ccs.conventionid = cs.conventionid
						AND ccs.startdate = cs.startdate
                        AND cs.ConventionStateID IN ('REE', 'TRA')
				) css ON C11.ConventionID = css.conventionid
			LEFT JOIN dbo.Un_Unit u11 ON c11.ConventionID = u11.ConventionID
				AND u11.TerminatedDate IS NULL
                AND CAST(YEAR(u11.signaturedate) + 35 AS VARCHAR) + '-12-31' < GETDATE()
            WHERE	u11.ConventionID IS NOT NULL
			) v35 ON v35.SubscriberID = s14.SubscriberID
        LEFT JOIN (-- Sousc complement OUT
			SELECT
				C7.SubscriberID,
                DateOut,
                NbGrUnit = COUNT(*)
            FROM dbo.Un_Unit U7
            JOIN dbo.Un_Convention C7 ON U7.ConventionID = C7.ConventionID
            JOIN (
				SELECT
					C8.SubscriberID,
                    nbOut = COUNT(*),
                    DateOut = MAX(terminateddate)
                FROM dbo.Un_Unit un8
                JOIN dbo.Un_Convention C8 ON Un8.ConventionID = C8.ConventionID
                JOIN (
					SELECT
						us.unitid,
                        uus.startdate,
                        us.UnitStateID
					FROM Un_UnitunitState us
                    JOIN (
						SELECT
							unitid,
                            startdate = MAX(startDate)
						FROM un_unitunitstate
						--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2010-06-01'
                        GROUP BY
							unitid
						) uus ON uus.unitid = us.unitid
							AND uus.startdate = us.startdate
                            AND us.UnitStateID = 'OUT'
					) uss ON un8.UnitID = uss.UnitID
				WHERE terminateddate IS NOT NULL
                GROUP BY
					C8.SubscriberID
				) Resil ON C7.SubscriberID = Resil.SubscriberID
			GROUP BY
				C7.SubscriberID,
                Resil.nbOut,
                Resil.DateOut
			HAVING COUNT(*) = Resil.nbOut
				) COut ON COut.SubscriberID = s14.SubscriberID
		WHERE b3.subscriberid IS NOT NULL
			OR v35.subscriberid IS NOT NULL
            OR COut.subscriberid IS NOT NULL
		) ferme ON ferme.SubscriberID = ChRep.iID_Souscripteur
    JOIN dbo.Mo_Adr adr ON hs.AdrID = adr.AdrID
    WHERE ((@iRepIDOri = 0
			OR ChRep.OldRepID = @iRepIDOri
			OR BossOri.OldBossID = @iRepIDOri)
		AND (@iRepIDNew = 0
			OR ChRep.NewRepID = @iRepIDNew
            OR BossNew.NewBossID = @iRepIDNew))
        AND ((RN.Repid IS NOT NULL
			OR RO.Repid IS NOT NULL))
	ORDER BY
		ht.FirstName + ' ' + ht.LastName,
        dDate_Statut,
        CASE WHEN BossOri.OldBossID IS NULL THEN 'ND' ELSE hob.FirstName + ' ' + hob.LastName END,
        CASE WHEN ChRep.OldRepID = -1 THEN 'ND' ELSE hor.FirstName + ' ' + hor.LastName END,
        hbn.FirstName + ' ' + hbn.LastName,
        hnr.FirstName + ' ' + hnr.LastName

    SELECT * FROM #tpsCONV_RapportChangementRepresentants

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tpsCONV_RapportChangementRepresentants', 
            @vcNom_ChampIdentifiant = 'iID_Souscripteur', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 1, 
            @bAcces_Adresse = 1
    --------------
    -- AUDIT - FIN
    --------------
    END 

END