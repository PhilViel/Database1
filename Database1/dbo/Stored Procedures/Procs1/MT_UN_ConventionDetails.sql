/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :     MT_UN_ConventionDetails
Description         :     Procédure de matrice des conventions.  Retourne les données de souscripteur, bénéficiaire,
                        conventions, groupe d'unités et parfois de représentant sous forme de grille matricielle.

Exemple d'appel        :    EXECUTE dbo.MT_UN_ConventionDetails 2,'311121','CON'

Valeurs de retours  :     Dataset de données
Note                :                            
                        2004-04-26  Dominic Létourneau      Migration
                        2004-04-30  Dominic Létourneau      Modification pour 10.23.1 (2.2) : Retrouve l'état actuel d'une convention.  
                                                            Modification pour 10.23.1 (3.2) : Retrouve l'état actuel d'un groupe d'unités.
                        2004-05-26  Dominic Létourneau      09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique    
                        2004-05-26  Dominic Létourneau      Ajout de la langue maternelle pour point 10.53.01 (2.2)
                        2004-05-31  Bruno Lapointe          Ajout du marqueur d'adresse perdue pour le point 10.8.7.1 (1.5)
                        2004-05-31  Bruno Lapointe          10.34 (1.2, 2.2, 3.2) : Retourne le nom du directeur du groupe d'unités, le nom 
                                                            du directeur du souscripteur et le nom du directeur du représentant.
                        2004-06-16  Bruno Lapointe          Point 13.10 : Montant total de subvention sur la convention
        ADX0000525  BR  2004-06-21  Bruno Lapointe 
        ADX0000933  BR  2004-08-20  Bruno Lapointe          Ajout d'un filtre sur le type de rechercher bénéficiaire si l'usager qui l'appelle est un représentant.
        ADX0000915  BR  2004-08-20  Bruno Lapointe          Ajout du champs texte du diplôme comme valeur de retour.  
        ADX0000985  BR  2004-08-23  Bruno Lapointe          Pas de virgule si le représentant du souscripteur est null.
        ADX0001092  BR  2004-09-30  Bruno Lapointe          Optimisation
        ADX0000589  IA  2004-11-19  Bruno Lapointe          Ajout du champs de date du dernier dépôt pour contrat et relevés de dépôts
        ADX0001213  BR  2005-02-02  Bruno Lapointe          Correction des valeurs de retour indiquant s'il y a un arrêt de paiement d'actif ou non.
        ADX0000670  IA  2005-03-14  Bruno Lapointe          Retourner la date de dernier dépôt pour relevés et contrats du groupe d'unités au lieu de la convention.
        ADX0001350  BR  2005-03-21  Bruno Lapointe          Correction du compteur d'horaire de prélèvement
        ADX0000692  IA  2005-05-04  Bruno Lapointe          Gestion des tuteurs
        ADX0000730  IA  2005-06-22  Bruno Lapointe          Enlever le ProgramCode
        ADX0000706  IA  2005-07-13  Bruno Lapointe          Ajout de la valeur de retour bBeneficiaryAddressLost
        ADX0001517  BR  2005-07-15  Bruno Lapointe          Le CollegeName avait comme valeur le CollegeID.
        ADX0000826  IA  2006-03-14  Bruno Lapointe          Adaptation des souscripteurs pour PCEE 4.3
        ADX0000830  IA  2006-03-17  Bruno Lapointe          Adaptation des bénéficiaires pour PCEE 4.3
        ADX0000798  IA  2006-03-17  Bruno Lapointe          Saisie des principaux responsables
        ADX0000831  IA  2006-03-20  Bruno Lapointe          Adaptation des conventions pour PCEE 4.3
        ADX0001978  BR  2006-06-15  Bruno Lapointe          Matrice de bénéficiaire donnait parfois une erreur de clef primaire sur la table #tConvention.
        ADX0001119  IA  2006-10-31  Alain Quirion           Ajout du champ fAvailableUnitQty
        ADX0001114  IA  2006-11-17  Alain Quirion           Ajout du champ IntReimbDateAdjust
        ADX0001185  IA  2006-12-05  Bruno Lapointe          Optimisation
        ADX0001241  IA  2007-04-11  Alain Quirion           Ajout des champs Spouse, Contact1, Contact2, Contact1Phone, Contact2Phone
        ADX0002426  BR  2007-05-22  Alain Quirion           Modification : Un_CESP au lieu de Un_CESP900
        ADX0001357  IA  2007-06-04  Alain Quirion           Ajout de bIsContestWinner
        ADX0001355  IA  2007-06-06  Alain Quirion           Suppression de RegEndDateAddYear, Ajout de : dtRegEndDateAdjust, dtCotisationEndDateAdjust, dtConvInforceDateTIN, dtInforceDateTIN
        ADX0001355  IA  2007-08-23  B.L.                    Ajout de : YearQty
                        2008-01-03  Pierre-Luc Simard       Ajout du code du représentant et du mot Inactif au prénom des représentants lorsqu'ils ont une date de fin de contrat
                        2008-07-03  Jean-Francois Arial     Ajout du numéro de convention individuelle pour une convention RIO
                        2008-09-15  Radu Trandafir          Ajout du champ PaysOrigine 
                                                            Ajout du champ PreferenceSuivi
                                                            Ajout du champ DestinationRemboursementID
                                                            Ajout du champ DestinationRemboursementAutre
                                                            Ajout du champ DateduProspectus    
                                                            Ajout du champ SouscripteurDesireIQEE
                                                            Ajout du champ LienCoSouscripteur
                                                            Ajout de la table tblCONV_ProfilSouscripteur
                        2008-10-02  Patrick Robitaille      Ajout du champ vcNEQ
                        2009-01-27  Éric Deshaies           Rétablissement du code enlevant les doublons dans les conventions touchées par un RIO
                        2009-02-12  Patrick Robitaille      Ajout du champ vcNIP dans la table Mo_Human
                        2009-06-16  Patrick Robitaille      Ajout de champs:
                                                                iSous_Cat_ID dans la table Un_Unit
                                                                bSouscripteur_Desire_Releve_Elect dans la table Un_Subscriber
                                                                bTuteur_Desire_Releve_Elect dans la table Un_Convention
                                                                bHumain_Accepte_Publipostage dans la table Mo_Human (Pour souscripteur et beneficiaire)
                        2009-09-30  Radu Trandafir          Ajout du champ iSous_Cat_ID_Resp_Prelevement 
                        2010-01-06  Jean-François Gauthier  Ajout des champs liés au profil souscripteur
                        2010-01-07  Jean-François Gauthier  Correction pour le profil souscripteur
                        2010-01-18  Jean-François Gauthier  Modification pour inclure le champ EligibilityConditionID de la table Un_Beneficiary en retour
                        2010-01-25  Jean-François Gauthier  Élimination d'un left outer join inutile sur Un_Beneficiary
                        2010-02-26  Jean-François Gauthier  Ajout du champ iNumeroBDNI en retour
                        2010-03-15  Jean-François Gauthier  Ajout des champs dtRegStartDate, bSouscripteur_Desire_IQEE, et des montants IQEE et IQEE+ 
                        2010-07-15  Éric Deshaies           Faire que le montant de rendement sur les subventions inclus l'IQÉÉ et aussi
                                                            les rendements sur les subventions fédérale bonifié et BEC et autres rendements
                                                            qui n'étaient pas comptés.
                        2010-12-06  Donald Huppé            afficher la première convention destination RIO générée car il peut y en avoir plus qu'une
                        2011-03-01  Jean-Françcois Gauthier Élimination de la contrainte sur la table #tConvention, car cela cause problème dans un contexte multi-usagers
                                                            Remplacement du "alter procedure"
                        2011-05-04  Corentin Menthonnex     Ajout de la gestion du TRI et RIM, on retourne désormais le OperTypeID (ConventionTypeInd) de l'opération RIO
                                                            afin de l'afficher lorsque la convention collective est la source d'un RIO/RIM ou TRI.
                        2011-05-11  Corentin Menthonnex     Mise à jour du profil souscripteur pour projet 2011-12.
                        2011-06-23  Corentin Menthonnex     Mise à jour du profil souscripteur pour projet 2011-12, rajout du champ bEtats_Financiers_Semestriels
                        2011-10-24  Christian Chénard       Modification de la table reliée aux colonnes iID_Identite_Souscripteur et vcIdentiteVerifieeDescription (de tblCONV_ProfilSouscripteur à Un_Subscriber)
                        2011-10-28  Christian Chénard       Ajout des champs iID_Estimation_Cout_Etudes, iID_Estimation_Valeur_Nette_Menage et vcCommInstrSpec
                        2011-11-02  Christian Chénard       Ajout du champ bAutorisation_Resiliation
                        2011-11-08  Christian Chénard       Ajout du champ iID_Justification_Conv_Incomplete
                        2011-11-16  Christian Chénard       Ajout du champ bAImprimer                            
                        2012-01-05  Eric Michaud            Ajout des champs bStatutPortailSubscriber,bStatutPortailBeneficiary    
                        2012-05-23  Donald Huppé            Ajout de bConsentement_Souscripteur et bConsentement_Beneficiaire qui remplace bConsentement
                        2012-07-17  Eric Michaud            Ajout des champs vcDossierBeneficiaire,vcDossierSouscripteur
                        2012-09-06  Donald Huppé            Gestion des / et \ dans vcDossierBeneficiaire,vcDossierSouscripteur
                        2012-09-14  Donald Huppé            Ajout de ToleranceRisqueID
                        2012-11-15  Donald Huppé            Dans le cas de convention issu de RIO ou RIM, retourner FeeByUnit = 0 (GLPI 8360)
                        2014-02-20  Pierre-Luc Simard       Utilisation du champ bReleve_Papier au lieu de bConsenement et bSouscripteur_Desire_Releve_Elect
                        2014-09-12  Pierre-Luc Simard       Récupérer uniquement le dernier profil souscripteur
                        2015-07-29  Steeve Picard           Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
                        2016-02-26  Steeve Picard           Prendre en charge les cas de date post-datée lorsqu'on affiche «Inactif» pour le représentant
                        2016-08-22  Steeve Picard           Remplacement de la fonction «fnIQEE_ObtenirDateDebutRegime» par «fnIQEE_ObtenirDateEnregistrementRQ»
                        2017-03-20  Steeve Bélanger         Ajout du champ tiMaximisationREEE
                        2017-12-05  Pierre-Luc Simard       Ne plus valider la table Un_RepBusinessBonusCfg
						2018-11-20	Maxime Martel			Utilisation du champ sur le beneficiaire pour EligibilityConditionID

exec MT_UN_ConventionDetails 530552 , 384732,'CON'
exec MT_UN_ConventionDetails 530552 , 575993,'SUB'
exec MT_UN_ConventionDetails 530552 , 251934,'BNF'
*************************************************************************************************************************/
CREATE PROCEDURE [dbo].[MT_UN_ConventionDetails] (    
    @ConnectID INTEGER, -- ID unique de connexion de l'usager
    @MatrixID INTEGER, -- ID Unique de l'objet qu'on recherche (ConventionID, RepID, SubscriberID ou BeneficiairyID selon le cas)
    @MatrixType VARCHAR(75) )    -- Type d'objet qu'on recherche : 
                                        --        SUB = Souscripteur
                                        --        CON = Convention
                                        --        BNF = Bénéficiaire
                                        --        REP = Représentant
                                        --        TUT = Tuteur (type ajouté)
AS
BEGIN
    DECLARE @Today DATETIME,
            @vcCONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION VARCHAR(100)

    SET @Today = GETDATE()
    SET @vcCONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION = dbo.fnOPER_ObtenirTypesOperationConvCategorie('CONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION')

    -- Table temporaire de nombre d'année à ajouter à la date d'entrée en vigueur
    -- pour déterminer la date de fin de cotisation
    DECLARE @tUn_MaxConvDepositDateCfg TABLE (
        dtStart DATETIME NOT NULL,
        dtEnd DATETIME NOT NULL,
        YearQty INT NOT NULL )

    INSERT INTO @tUn_MaxConvDepositDateCfg
    SELECT
        dtStart = M.EffectDate,
        dtEnd = ISNULL(MIN(M2.EffectDate)-1, dbo.fn_CRQ_DateNoTime(GETDATE())),
        M.YearQty
    FROM Un_MaxConvDepositDateCfg M
    LEFT JOIN Un_MaxConvDepositDateCfg M2 ON M2.EffectDate > M.EffectDate OR (M2.EffectDate = M.EffectDate AND M2.MaxConvDepositDateCfgID > M.MaxConvDepositDateCfgID)
    GROUP BY
        M.EffectDate,
        M.YearQty

    IF @MatrixType = 'SUB' -- Souscripteur
    BEGIN
        SELECT
            S.SubscriberID,
            /*SRepName = 
                CASE 
                    WHEN R.HumanID IS NULL THEN ''
                    ELSE R.LastName + ', ' + R.FirstName
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            SRepName = IsNull(R.LastName + ', ' + R.FirstName + ' (' + R_Rep.Repcode + ')', '')
                       + CASE WHEN IsNull(R_Rep.BusinessEnd, GetDate()) < getDate() THEN ' (Inactif)' ELSE '' END,
            S.RepID,
            S.ScholarshipLevelID,
            S.AnnualIncome,
            S.StateID,
            S.SemiAnnualStatement,
            SFirstName = SH.FirstName,
            SOrigName = SH.OrigName,
            SLastName = SH.LastName,
            SvcNIP = ISNULL(SH.vcNIP, ''),
            SCompanyName = SH.CompanyName,
            SSexID = SH.SexID,
            SAdrID = SH.AdrID,
            SBirthDate = SH.BirthDate,
            SDeathDate = SH.DeathDate,
            SLangID = SH.LangID,
            SCivilID = SH.CivilID,
            SCourtesyTitle = SH.CourtesyTitle,
            SUsingSocialNumber = SH.UsingSocialNumber,
            SSharePersonalInfo = SH.SharePersonalInfo,
            SMarketingMaterial = SH.MarketingMaterial,
            SIsCompany = SH.IsCompany,
            SSocialNumber = SH.SocialNumber,
            SDriverLicenseNo = SH.DriverLicenseNo,
            SWebSite = SH.WebSite,
            SResidID = SH.ResidID,
            SInForce = SA.InForce,
            SAdrTypeID = SA.AdrTypeID,
            SSourceID = SA.SourceID,
            SAddress = SA.Address,
            SCity = SA.City,
            SStateName = SA.StateName,
            SCountryID = SA.CountryID,
            SZipCode = SA.ZipCode,
            SPhone1 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone1, SA.CountryID),
            SPhone2 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone2, SA.CountryID),
            SFax = dbo.FN_CRQ_FormatPhoneNo(SA.Fax, SA.CountryID),
            SMobile = dbo.FN_CRQ_FormatPhoneNo(SA.Mobile, SA.CountryID),
            SWattLine = dbo.FN_CRQ_FormatPhoneNo(SA.WattLine, SA.CountryID),
            SOtherTel = dbo.FN_CRQ_FormatPhoneNo(SA.OtherTel, SA.CountryID),
            SPager = dbo.FN_CRQ_FormatPhoneNo(SA.Pager, SA.CountryID),
            SEMail = SA.EMail,            
            tiSubsCESPState = S.tiCESPState, -- État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)
            Spouse = ISNULL(S.Spouse,''),
            Contact1 = ISNULL(S.Contact1,''),
            Contact2 = ISNULL(S.Contact2,''),
            Contact1Phone = ISNULL(S.Contact1Phone,''),
            Contact2Phone = ISNULL(S.Contact2Phone,''),
            SNEQ = ISNULL(SH.StateCompanyNo,''),
            bSouscripteur_Desire_Releve_Elect = ISNULL(S.bReleve_Papier,0), 
            bSouscripteur_Accepte_Publipostage = SH.bHumain_Accepte_Publipostage,
            B.BeneficiaryID,
            B.GovernmentGrantForm,
            B.BirthCertificate,
            B.PersonalInfo,
            B.ProgramID,
            B.ProgramLength,
            B.ProgramYear,
            B.SchoolReport,
            B.RegistrationProof,
            B.StudyStart,
            B.CaseOfJanuary,
            B.EligibilityQty,
            B.CollegeID,
            bBeneficiaryAddressLost = B.bAddressLost,
            tiPCGType =
                CASE 
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 0 THEN 0
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 1 THEN 1
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 1 THEN 2
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 0 THEN 3
                END, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise-Souscripteur, 3=Entreprise)
            B.vcPCGFirstName, -- Prénom du principal responsable s’il s’agit d’un souscripteur ou d’une personne. Nom de l’entreprise principal responsable dans l’autre cas.
            B.vcPCGLastName, -- Nom du principal responsable s’il s’agit d’un souscripteur ou d’une personne.
            B.vcPCGSINOrEN, -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
            bBeneficiaire_Accepte_Publipostage = BH.bHumain_Accepte_Publipostage,
            tiBenefCESPState = B.tiCESPState,
            Co.CollegeTypeID,
            B.EligibilityConditionID,
            Co.CollegeCode,
            CollegeName = CoCo.CompanyName,
            Prog.ProgramDesc,
            BFirstName = BH.FirstName,
            BOrigName = BH.OrigName,
            BInitial = BH.Initial,
            BLastName = BH.LastName,
            BvcNIP = ISNULL(BH.vcNIP, ''),
            BCompanyName = BH.CompanyName,
            BSexID = BH.SexID,
            BAdrID = BH.AdrID,
            BBirthDate = BH.BirthDate,
            BDeathDate = BH.DeathDate,
            BLangID = BH.LangID,
            BCivilID = BH.CivilID,
            BCourtesyTitle = BH.CourtesyTitle,
            BUsingSocialNumber = BH.UsingSocialNumber,
            BSharePersonalInfo = BH.SharePersonalInfo,
            BMarketingMaterial = BH.MarketingMaterial,
            BIsCompany = BH.IsCompany,
            BSocialNumber = BH.SocialNumber,
            BDriverLicenseNo = BH.DriverLicenseNo,
            BWebSite = BH.WebSite,
            BNEQ = ISNULL(BH.StateCompanyNo,''),
            BResidID = BH.ResidID,
            BInForce = BA.InForce,
            BAdrTypeID = BA.AdrTypeID,
            BSourceID = BA.SourceID,
            BAddress = BA.Address,
            BCity = BA.City,
            BStateName = BA.StateName,
            BCountryID = BA.CountryID,
            BZipCode = BA.ZipCode,
            BPhone1 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone1, BA.CountryID),
            BPhone2 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone2, BA.CountryID),
            BFax = dbo.FN_CRQ_FormatPhoneNo(BA.Fax, BA.CountryID),
            BMobile = dbo.FN_CRQ_FormatPhoneNo(BA.Mobile, BA.CountryID),
            BWattLine = dbo.FN_CRQ_FormatPhoneNo(BA.WattLine, BA.CountryID),
            BOtherTel = dbo.FN_CRQ_FormatPhoneNo(BA.OtherTel, BA.CountryID),
            BPager = dbo.FN_CRQ_FormatPhoneNo(BA.Pager, BA.CountryID),
            BEMail = BA.EMail,
            C.ConventionID,
            C.ConventionNo,
            C.YearQualif,
            C.tiMaximisationREEE,
            PmtDate = C.FirstPmtDate,
            C.PmtTypeID,
            C.tiRelationshipTypeID,
            RT.vcRelationshipType,
            C.GovernmentRegDate,
            C.ScholarshipYear,
            C.ScholarshipEntryID,
            C.dtRegEndDateAdjust,
            dtConvInforceDateTIN = C.dtInforceDateTIN,
            C.CoSubscriberID,
            CPlanID = PC.PlanID,
            CPlanTypeID = PC.PlanTypeID,
            CPlanDesc = PC.PlanDesc,
            C.bTuteur_Desire_Releve_Elect,
            U.UnitID,
            U.UnitQty,
            U.InForceDate,
            U.SignatureDate,
            U.TerminatedDate,
            U.IntReimbDate,
            U.ActivationConnectID,
            U.ValidationConnectID,
            U.BenefInsurID,
            U.WantSubscriberInsurance,            
            URepID = U.RepID,
            /*URepName = 
                CASE ISNULL(U.RepID,0) 
                    WHEN 0 THEN '' 
                ELSE UR.LastName + ', ' + UR.FirstName 
                END, 
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepName = IsNull(UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')', '')
                       + CASE WHEN IsNull(UR_Rep.BusinessEnd, GetDate()) < getDate() THEN ' (Inactif)' ELSE '' END,
            URepResponsableID = U.RepResponsableID,
            U.PmtEndConnectID,
            U.IntReimbDateAdjust,
            /*URepResponsableName = 
                CASE ISNULL(U.RepResponsableID,0) 
                    WHEN 0 THEN '' 
                ELSE URR.LastName + ', ' + URR.FirstName 
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepResponsableName = CASE WHEN URR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            U.StopRepComConnectID,
            U.SubscribeAmountAjustment,
            U.LastDepositForDoc,
            U.dtCotisationEndDateAdjust,
            U.dtInforceDateTIN,
            U.iSous_Cat_ID,
            MCD.YearQty,
            M.ModalID,
            M.ModalDate,
            M.PmtByYearID,
            M.PmtQty,
            M.PmtRate,
            M.SubscriberInsuranceRate,
            M.BenefAgeOnBegining,
            FeeByUnit = CASE WHEN FBU.iID_Convention_Destination IS NULL THEN  M.FeeByUnit ELSE 0 END,
            M.FeeSplitByUnit,
            M.FeeRefundable,
            P.tiAgeQualif,
            M.BusinessBonusToPay,
            BI.BenefInsurDate,
            BI.BenefInsurFaceValue,
            BI.BenefInsurPmtByYear,
            BI.BenefInsurRate,
            P.PlanID,
            P.PlanDesc,
            P.PlanTypeID,
            P.IntReimbAge,
            CA.BankID,
            CA.AccountName,
            CA.TransitNo,
            BK.BankTransit,
            BK.BankName,
            BK.BankTypeName,
            BK.BankTypeCode,
            ConventionBreaking = ISNULL(BKG.ConventionID,0),
            UnitHoldPayment = ISNULL(UHP.UnitID,0),
            StateTaxPct = ISNULL(St.StateTaxPct,0),
            FirstPmtDate = Ct.OperDate,
            Cotisation = ISNULL(Ct.Cotisation, 0),
            Fee = ISNULL(Ct.Fee, 0),
            CapitalInterestAmount = ISNULL(CI.CapitalInterestAmount, 0),
            GrantInterestAmount = ISNULL(CG.GrantInterestAmount, 0),
            AvailableFeeAmount = ISNULL(CF.AvailableFeeAmount, 0),
            AutomaticDepositCount = ISNULL(AD.AutomaticDepositCount, 0),
            CoSubscriberName = 
                CASE 
                    WHEN ISNULL(C.CoSubscriberID, 0) = 0 THEN '' 
                    WHEN SHC.IsCompany = 1 THEN SHC.LastName
                ELSE SHC.LastName + ', ' + SHC.FirstName 
                END,
            NbNSF = ISNULL(NSF.NbNSF,0),
            SS.SaleSourceID,   -- point 718
            SS.SaleSourceDesc, -- point 718
            bIsContestWinner = ISNULL(SS.bIsContestWinner,0),
            TotalCapitalInsured = 
                CASE 
                    WHEN ISNULL(TC.TotalCapitalInsured,0) > 0 THEN TC.TotalCapitalInsured 
                ELSE 0 
                END, -- point 729
            CESGInForceDate = GGI.InForceDate, -- #0768-05
            CS.ConventionStateID,
            CS.ConventionStateName,
            US.UnitStateID,
            US.UnitStateName,
            AutoMonthTheoricAmount = 
                CASE ISNULL(C.PmtTypeID, '') 
                    WHEN 'AUT' THEN ISNULL(AMT.MonthTheoricAmount,0) 
                END, -- Valeur retournée seulement si paiement automatique
            BirthLangID = ISNULL(WorldLanguageCodeID,''),
            BirthLangName = ISNULL(WorldLanguage,''),
            S.AddressLost,
            UDirName = 
                CASE ISNULL(UDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HUDIR.LastName + ', ' + HUDIR.FirstName 
                END,
            SDirName = 
                CASE ISNULL(SDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HSDIR.LastName + ', ' + HSDIR.FirstName 
                END,
            C.bSendToCESP, -- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
            fCESG = ISNULL(GG.fCESG,0), -- Solde du compte de SCEE de la convention.
            fACESG = ISNULL(GG.fACESG,0), -- Solde du compte de SCEE+ de la convention.
            fCLB = ISNULL(GG.fCLB,0), -- Solde du compte de BEC de la convention.
            C.bCESGRequested, -- SCEE voulue (1) ou non (2)
            C.bACESGRequested, -- SCEE+ voulue (1) ou non (2)
            C.bCLBRequested, -- BEC voulu (1) ou non (2)
            C.tiCESPState, -- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
            DiplomaTextID = 9999, -- DT.DiplomaTextID,  -- ID unique du texte du diplôme        -- 2015-07-29
            DiplomaText = ISNULL(C.TexteDiplome, ''), -- DT.DiplomaText, -- Texte du diplôme        -- 2015-07-29
            B.iTutorID, -- ID du tuteur, correspond au HumanID.
            B.bTutorIsSubscriber, -- Si le Tuteur est un souscripteur ou non
            TvcEN = Tu.vcEN, -- Numéro d’entreprise, si le tuteur en est une.
            TFirstName = TuH.FirstName, -- Prénom du tuteur
            TOrigName = TuH.OrigName, -- Nom à la naissance
            TInitial = TuH.Initial, -- Initial (Jr, Sr, etc.)
            TLastName = TuH.LastName, -- Nom
            TvcNIP = ISNULL(TuH.vcNIP, ''),
            TBirthDate = TuH.BirthDate, -- Date de naissance
            TDeathDate = TuH.DeathDate, -- Date du décès
            TSexID = TuH.SexID, -- Sexe (code)
            TLangID = TuH.LangID, -- Langue (code)
            TCivilID = TuH.CivilID, -- Statut civil (code)
            TSocialNumber = TuH.SocialNumber, -- Numéro d’assurance sociale
            TResidID = TuH.ResidID, -- Pays de résidence (code)
            TDriverLicenseNo = TuH.DriverLicenseNo, -- Numéro de permis
            TWebSite = TuH.WebSite, -- Site internet
            TCourtesyTitle = TuH.CourtesyTitle, -- Titre de courtoisie (Docteur, Professeur, etc.)
            TUsingSocialNumber = TuH.UsingSocialNumber, -- Droit d’utiliser le NAS.
            TSharePersonalInfo = TuH.SharePersonalInfo, -- Droit de partager les informations personnelles
            TMarketingMaterial = TuH.MarketingMaterial, -- Veux recevoir le matériel publicitaire.
            TIsCompany = TuH.IsCompany, -- Compagny ou humain
            TInForce = TuA.InForce, -- Date d’entrée en vigueur de l’adresse.
            TAdrTypeID = TuA.AdrTypeID, -- Type d’adresse (H = humain, C = Compagnie)
            TSourceID = TuA.SourceID, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
            TAddress = TuA.Address, -- # civique, rue et # d’appartement.
            TCity = TuA.City, -- Ville
            TStateName = TuA.StateName, -- Province
            TCountryID = TuA.CountryID, -- Pays (code)
            TZipCode = TuA.ZipCode, -- Code postal
            TPhone1 = TuA.Phone1, -- Tél. résidence
            TPhone2 = TuA.Phone2, -- Tél. bureau
            TFax = TuA.Fax, -- Fax
            TMobile = TuA.Mobile, -- Tél. cellulaire
            TWattLine = TuA.WattLine, -- Tél. sans frais
            TOtherTel = TuA.OtherTel, -- Autre téléphone.
            TPager = TuA.Pager, -- Paget
            TEmail = TuA.Email, -- Courriel
            fAvailableUnitQty = ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0),
            ConventionIDInd=C2.ConventionID, --Id convention individuelle RIO
            ConventionNoInd=C2.ConventionNo, --No convnetion individuelle RIO                
            PaysOrigine = ISNULL(Corg.CountryName, ''), --Pays d'origine            
            PreferenceSuiviID = ISNULL(S.iID_Preference_Suivi, 0), --Preference suivi
            NoPersonnesaCharge=ISNULL(PS.tiNB_Personnes_A_Charge,0), --Ajout de la table tblCONV_ProfilSouscripteur
            ConnaisancePlacementID=ISNULL(PS.iID_Connaissance_Placements,0),
            RevenuFamilialID=ISNULL(PS.iID_Revenu_Familial,0),
            DepassementBaremeID=ISNULL(PS.iID_Depassement_Bareme,0),
            IdentiteSouscripteurID=ISNULL(S.iID_Identite_Souscripteur,0),
            ObjectifInvestissementLigne1ID=ISNULL(PS.iID_ObjectifInvestissementLigne1,0),
            ObjectifInvestissementLigne2ID=ISNULL(PS.iID_ObjectifInvestissementLigne2,0),
            ObjectifInvestissementLigne3ID=ISNULL(PS.iID_ObjectifInvestissementLigne3,0),
            IdentiteDescription=ISNULL(S.vcIdentiteVerifieeDescription,''),
            AutorisationResiliation=ISNULL(S.bAutorisation_Resiliation,0),
            DepassementJustification=ISNULL(PS.vcDepassementbaremeJustification,''),
            EstimationCoutEtudesID = ISNULL(PS.iID_Estimation_Cout_Etudes, 0),
            EstimationValeurNetteMenageID = ISNULL(PS.iID_Estimation_Valeur_Nette_Menage, 0), 
            DestinationRemboursementID=ISNULL(C.iID_Destinataire_Remboursement, 0), --L'ID du Destination remboursement
            DestinationRemboursementAutre=ISNULL(C.vcDestinataire_Remboursement_Autre, ''), --Destination remboursement autre
            DateduProspectus=ISNULL(C.dtDateProspectus, ''), --Date du prospectus
            SouscripteurDesireIQEE=ISNULL(C.bSouscripteur_Desire_IQEE, 0), --Souscripteur desire IQEE
            C.tiID_Lien_CoSouscripteur,
            LienCoSouscripteur=ISNULL(LC.vcRelationshipType,''),
            C.iSous_Cat_ID_Resp_Prelevement,
            IDNiveauEtudeMere        = ISNULL(PS.iIDNiveauEtudeMere,    0),            -- 2010-01-06 : JFG :Modification des champs du profil souscripteur
            IDNiveauEtudePere        = ISNULL(PS.iIDNiveauEtudePere, 0),
            IDNiveauEtudeTuteur        = ISNULL(PS.iIDNiveauEtudeTuteur, 0),
            IDImportanceEtude        = ISNULL(PS.iIDImportanceEtude, 0),
            IDEpargneEtudeEnCours    = ISNULL(PS.iIDEpargneEtudeEnCours, 0),
            IDContributionFinanciereParent = ISNULL(PS.iIDContributionFinanciereParent,    0),
            IDConditionEligibleBenef = ISNULL(b.EligibilityConditionID, ''),
            UR_Rep.iNumeroBDNI,
            C.bFormulaireRecu,
            C.dtRegStartDate,
            C.bSouscripteur_Desire_IQEE,
            IQEE        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            IQEEMaj        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            ConventionTypeInd                = S1.OperTypeID,                                    -- Type de la convention individuelle (RIO, RIM ou TRI)    
            vcOccupation                    = ISNULL(SH.vcOccupation, ''),                        -- Occupation de l'humain    
            vcEmployeur                        = ISNULL(SH.vcEmployeur, ''),                        -- Employeur de l'humain    
            tiNbAnneesService                = ISNULL(SH.tiNbAnneesService, ''),                    -- Nombre d'années de service    
            bRapport_Annuel_Direction        = ISNULL(S.bRapport_Annuel_Direction, 0),            -- Désire le rapport annuel de la direction
            bEtats_Financiers_Annuels        = ISNULL(S.bEtats_Financiers_Annuels, 0),            -- Désire les états financiers annuels    
            vcJustifObjectifsInvestissement    = ISNULL(PS.vcJustifObjectifsInvestissement, ''),    -- Justification du choix des objectifs d'investissement
            bEtats_Financiers_Semestriels    = ISNULL(S.bEtats_Financiers_Semestriels, 0),        -- Désire les états financiers semestriels    
            C.vcCommInstrSpec,
            iIDJustificationConvIncomplete = ISNULL(C.iID_Justification_Conv_Incomplete, 0),
--            bAImprimer                       = ISNULL(C.bAImprimer, 0),
            bStatutPortailSubscriber       = CASE when PAS.iUserId is NULL THEN 0 ELSE 1 END,
            bStatutPortailBeneficiary       = CASE when PAB.iUserId is NULL THEN 0 ELSE 1 END,
            DateRQ = dbo.fnIQEE_ObtenirDateEnregistrementRQ(C.ConventionID), 
              DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL), 
            DateFinRegimeOriginale = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'T', NULL),
            DateEntreeVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
            ,bConsentement_Souscripteur = CASE WHEN ISNULL(PAS.iEtat, 0) = 5 THEN CAST('1' AS bit) ELSE cast('0' AS bit) END 
            ,bConsentement_Beneficiaire = ISNULL(B.bReleve_Papier,0)  
            ,vcDossierBeneficiaire = GPB.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(BH.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(BH.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(BH.firstname)),' ','_') + '_' + cast(BH.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,vcDossierSouscripteur = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(sh.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(sh.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(sh.firstname)),' ','_') + '_' + cast(sh.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,ToleranceRisqueID=ISNULL(PS.iID_Tolerance_Risque,0)
        FROM 
        Un_Subscriber S
        JOIN dbo.Mo_Human SH ON SH.HumanID = S.SubscriberID
        LEFT JOIN dbo.Mo_Adr SA ON SA.AdrID = SH.AdrID
        LEFT JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID        
        LEFT JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID
        LEFT JOIN ( -- Date de vigueur enregistrée à la SCÉÉ #0768-07
            SELECT 
                G.ConventionID,
                InForceDate = MIN(G.dtTransaction)
            FROM Un_CESP100 G
            LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
            JOIN (-- Retourne la plus grande date de fichier scee envoyé par convention
                            SELECT 
                                G.ConventionID,
                                dtCESPSendFile = MAX(ISNULL(S.dtCESPSendFile, @Today))
                            FROM Un_CESP100 G
                            JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
                            LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
                            WHERE C.SubscriberID = @MatrixID
                            GROUP BY G.ConventionID
                        ) V ON V.ConventionID = G.ConventionID AND ISNULL(S.dtCESPSendFile, @Today) = V.dtCESPSendFile
            GROUP BY G.ConventionID
            ) GGI ON GGI.ConventionID = C.ConventionID
        LEFT JOIN dbo.Mo_Human SHC ON SHC.HumanID = C.CoSubscriberID
        LEFT JOIN ( --point#729                                                                                       
            SELECT 
                V1.SubscriberID,
                TotalCapitalInsured = SubscribAmount - ISNULL(AmountToDate,0) 
            FROM (-- Retourne le total des montants versés par souscripteur                                                                     
                SELECT 
                    C.SubscriberID, 
                    SubscribAmount = SUM(ROUND(M.PmtRate*U.UnitQty,2) * PmtQty)
                FROM dbo.Un_Convention C                      
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Modal M ON M.ModalID = U.ModalID                                                
                WHERE C.SubscriberID = @MatrixID
                  AND U.WantSubscriberInsurance <> 0
                  AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID 
                ) V1                                                                   
          LEFT JOIN (-- Retourne les cotisations versées jusqu'à présent par souscripteurs
                SELECT 
                    C.SubscriberID,
                    AmountToDate = SUM(Co.Cotisation + Co.Fee)
                FROM dbo.Un_Convention C
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                WHERE C.SubscriberID = @MatrixID
                    AND U.WantSubscriberInsurance <> 0
                    AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID
                ) V2 ON V1.SubscriberID = V2.SubscriberID
            ) TC ON TC.SubscriberID = S.SubscriberID
        LEFT JOIN (-- Retourne la somme des intérêts sur montant souscrit par convention
            SELECT
                CO.ConventionID,
                CapitalInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            WHERE C.SubscriberID = @MatrixID
              AND CO.ConventionOperTypeID = 'INM'
            GROUP BY CO.ConventionID
            ) CI ON CI.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des intérêts sur subvention par convention
            SELECT
                CO.ConventionID,
                GrantInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            WHERE C.SubscriberID = @MatrixID
              AND CHARINDEX(','+CO.ConventionOperTypeID+',',@vcCONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION) > 0
            GROUP BY CO.ConventionID
            ) CG ON CG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des frais disponibles par convention
            SELECT
                CO.ConventionID,
                AvailableFeeAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            WHERE C.SubscriberID = @MatrixID
              AND CO.ConventionOperTypeID = 'FDI'
            GROUP BY CO.ConventionID                
            ) CF ON CF.ConventionID = C.ConventionID
        LEFT JOIN Un_Plan PC ON PC.PlanID = C.PlanID
        LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
        LEFT JOIN Un_Modal M ON M.ModalID = U.ModalID
        LEFT JOIN Un_Plan P ON P.PlanID = M.PlanID
        LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
        LEFT JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
        LEFT JOIN dbo.Mo_Adr BA ON BA.AdrID = BH.AdrID
        --LEFT JOIN dbo.Mo_Human R ON R.HumanID = S.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep R_Rep ON R_Rep.RepID = S.RepID
        LEFT JOIN dbo.Mo_Human R ON R.HumanID = R_Rep.RepID
        --LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = U.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep UR_Rep ON UR_Rep.RepID = U.RepID
        LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = UR_Rep.RepID
        --LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = U.RepResponsableID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep URR_Rep ON URR_Rep.RepID = U.RepResponsableID
        LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = URR_Rep.RepID
        LEFT JOIN (-- Retourne le total des cotisations et de frais ainsi que la plus petite date d'opération par unités
            SELECT
                Ct.UnitID,
                OperDate = MIN(O.OperDate),
                FEE = SUM(Ct.Fee),
                Cotisation = SUM(Ct.Cotisation)
            FROM Un_Cotisation Ct
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN Un_Oper O ON O.OperID = Ct.OperID
            LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
            WHERE C.SubscriberID = @MatrixID
                AND(    ( O.OperTypeID = 'CPA' 
                         AND OBF.OperID IS NOT NULL
                        )
                    OR O.OperDate <= GETDATE()
                    )
            GROUP BY Ct.UnitID
            ) Ct ON Ct.UnitID = U.UnitID
        LEFT JOIN (-- Sert à la détection d'un arrêt de paiement sur le groupe d'unité
            SELECT DISTINCT 
                H.UnitID 
            FROM Un_UnitHoldPayment H
            JOIN dbo.Un_Unit U ON U.UnitID = H.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            WHERE C.SubscriberID = @MatrixID
                AND H.StartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(H.EndDate,0) <= 0
                        OR H.EndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) UHP ON UHP.UnitID = U.UnitID
        LEFT JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
        LEFT JOIN ( -- Retourne l'info des banques
            SELECT DISTINCT
                B.BankID,
                B.BankTransit,
                BankName = C.CompanyName,
                BT.BankTypeName,
                BT.BankTypeCode
            FROM Mo_Bank B
            JOIN Mo_Company C ON C.CompanyID = B.BankID
            JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
            JOIN Un_ConventionAccount CA ON B.BankID = CA.BankID
            JOIN dbo.Un_Convention Co ON Co.ConventionID = CA.ConventionID
            WHERE Co.SubscriberID = @MatrixID
            ) BK ON BK.BankID = CA.BankID
        LEFT JOIN Un_Program Prog ON Prog.ProgramID = B.ProgramID
        LEFT JOIN Un_College Co ON Co.CollegeID = B.CollegeID
        LEFT JOIN Mo_Company CoCo ON CoCo.CompanyID = Co.CollegeID
        LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
        LEFT JOIN Mo_State St ON St.StateID = S.StateID
        LEFT JOIN (-- Retourne les conventions en arrêt de paiement
            SELECT DISTINCT 
                B.ConventionID
            FROM Un_Breaking B
            JOIN dbo.Un_Convention C ON C.ConventionID = B.ConventionID
            WHERE C.SubscriberID = @MatrixID
                AND B.BreakingStartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(B.BreakingEndDate,0) <= 0
                        OR B.BreakingEndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
                ) BKG ON BKG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne le nombre de dépôts par unité
            SELECT
                A.UnitID,
                AutomaticDepositCount = COUNT(A.AutomaticDepositID)
            FROM Un_AutomaticDeposit A
            JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            WHERE C.SubscriberID = @MatrixID
                AND    ( dbo.FN_CRQ_DateNoTime(GETDATE()) BETWEEN A.StartDate AND A.EndDate
                         OR    ( dbo.FN_CRQ_DateNoTime(GETDATE()) >= A.StartDate 
                                AND ISNULL(A.EndDate,0) < 2
                                )
                        )
            GROUP BY A.UnitID
            ) AD ON AD.UnitID = U.UnitID
        LEFT JOIN (-- Retourne le nombre de nsf par convention
            SELECT 
                U.ConventionID, 
                NbNSF = COUNT(DISTINCT O.OperID) 
            FROM Mo_BankReturnLink R
            JOIN Un_Oper O    ON O.OperID = R.BankReturnCodeID
            JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            WHERE C.SubscriberID = @MatrixID
              AND R.BankReturnTypeID = '901'
            GROUP BY U.ConventionID
            ) NSF ON NSF.ConventionID = C.ConventionID
        LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
        LEFT JOIN (-- 10.23.1 (2.2) : Retrouve l'état actuel d'une convention
            SELECT 
                T.ConventionID,
                CS.ConventionStateID,
                CS.ConventionStateName
            FROM (-- Retourne la plus grande date de début d'un état par convention
                SELECT 
                    S.ConventionID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_ConventionConventionState S
                JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
                WHERE C.SubscriberID = @MatrixID
                  AND S.StartDate <= GETDATE()
                GROUP BY S.ConventionID
                ) T
            JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
            JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
            ) CS ON C.ConventionID = CS.ConventionID
        LEFT JOIN (-- 10.23.1 (3.2) : Retrouve l'état actuel d'un groupe d'unités
            SELECT 
                T.UnitID,
                US.UnitStateID,
                US.UnitStateName
            FROM (-- Retourne la plus grande date de début d'un état par unité
                SELECT 
                    S.UnitID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_UnitUnitState S
                JOIN dbo.Un_Unit U ON U.UnitID = S.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                WHERE C.SubscriberID = @MatrixID
                  AND S.StartDate <= GETDATE()
                GROUP BY S.UnitID
                ) T
            JOIN Un_UnitUnitState UUS ON T.UnitID = UUS.UnitID AND T.MaxDate = UUS.StartDate -- Retrouve l'état correspondant à la plus grande date par unité
            JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID -- Pour retrouver la description de l'état
            ) US ON U.UnitID = US.UnitID
        LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
            SELECT
                U.ConventionID,
                MonthTheoricAmount = 
                    SUM(
                        ROUND(M.PmtRate * U.UnitQty,2) + -- Cotisation et frais
                        dbo.FN_CRQ_TaxRounding
                            ((    CASE U.WantSubscriberInsurance -- Assurance souscripteur
                                    WHEN 0 THEN 0
                                ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
                                END +
                                ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
                            (1+ISNULL(St.StateTaxPct,0)))) -- Taxes
            FROM dbo.Un_Unit U
            JOIN Un_Modal M ON U.ModalID = M.ModalID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            LEFT JOIN Mo_State St ON St.StateID = S.StateID
            LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
            LEFT JOIN (
                SELECT
                    U.UnitID,
                    CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
                FROM dbo.Un_Unit U
                JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                WHERE C.SubscriberID = @MatrixID
                GROUP BY U.UnitID
                ) Ct ON U.UnitID = Ct.UnitID
            WHERE C.SubscriberID = @MatrixID
              AND M.PmtByYearID = 12
              AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
            GROUP BY U.ConventionID
            ) AMT ON C.ConventionID = AMT.ConventionID 
        LEFT JOIN CRQ_WorldLang W ON S.BirthLangID = W.WorldLanguageCodeID
        LEFT JOIN (
            SELECT
                M.UnitID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    U.UnitID,
                    U.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Unit U
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
                JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
                JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
                WHERE C.SubscriberID = @MatrixID
                GROUP BY 
                    U.UnitID, 
                    U.RepID
                ) M
            JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
            WHERE C.SubscriberID = @MatrixID
            GROUP BY M.UnitID
            ) UDIR ON UDIR.UnitID = U.UnitID
        LEFT JOIN dbo.Mo_Human HUDIR ON HUDIR.HumanID = UDIR.BossID
        LEFT JOIN (
            SELECT
                M.SubscriberID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    S.SubscriberID,
                    S.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Subscriber S
                JOIN Un_RepBossHist RBH ON RBH.RepID = S.RepID AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
                JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
                JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)

                WHERE S.SubscriberID = @MatrixID
                GROUP BY 
                    S.SubscriberID, 
                    S.RepID
                ) M
            JOIN dbo.Un_Subscriber S ON (S.SubscriberID = M.SubscriberID)
            JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
            WHERE S.SubscriberID = @MatrixID
            GROUP BY M.SubscriberID
            ) SDIR ON SDIR.SubscriberID = S.SubscriberID
        LEFT JOIN dbo.Mo_Human HSDIR ON HSDIR.HumanID = SDIR.BossID
        LEFT JOIN (
            SELECT 
                CE.ConventionID,
                fCESG = SUM(CE.fCESG),
                fACESG = SUM(CE.fACESG),
                fCLB = SUM(CE.fCLB)
            FROM Un_CESP CE
            JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
            WHERE C.SubscriberID = @MatrixID
            GROUP BY CE.ConventionID
            ) GG ON GG.ConventionID = C.ConventionID
        --LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID        -- 2015-07-29
        LEFT JOIN Un_Tutor Tu ON Tu.iTutorID = B.iTutorID AND B.bTutorIsSubscriber = 0
        LEFT JOIN dbo.Mo_Human TuH ON TuH.HumanID = B.iTutorID
        LEFT JOIN dbo.Mo_Adr TuA ON TuA.AdrID = TuH.AdrID
        LEFT JOIN ( -- Unité résiliés
                SELECT 
                    C.ConventionID, 
                    UnitRes = SUM(UR.UnitQty)
                FROM Un_UnitReduction UR
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                WHERE C.SubscriberID = @MatrixID
                GROUP BY C.ConventionID) SR ON SR.ConventionID = C.ConventionID
        LEFT JOIN ( -- Unité utilisés
                SELECT 
                    C.ConventionID, 
                    UnitUse = SUM(A.fUnitQtyUse)
                FROM Un_UnitReduction UR
                JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID            
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                WHERE C.SubscriberID = @MatrixID
                GROUP BY C.ConventionID) SU ON SU.ConventionID = C.ConventionID
        LEFT JOIN @tUn_MaxConvDepositDateCfg MCD ON U.InForceDate BETWEEN MCD.dtStart AND MCD.dtEnd

        LEFT JOIN (SELECT iID_Convention_Source,iID_Convention_Destination = min(iID_Convention_Destination), iID_Unite_Source, TOPER.OperTypeID
                    FROM tblOPER_OperationsRIO TOPER 
                    WHERE (TOPER.bRIO_ANNULEE = 0 AND TOPER.bRIO_QUIANNULE = 0)
                    GROUP BY iID_Convention_Source, iID_Unite_Source, TOPER.OperTypeID) AS S1 ON S1.iID_Convention_Source = C.ConventionID  AND S1.iID_Unite_Source = U.UnitID
        LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = S1.iID_Convention_Destination
        LEFT JOIN Mo_Country Corg ON Corg.CountryID = SH.cID_Pays_Origine --Pays d'origine
        LEFT JOIN Un_RelationshipType LC ON LC.tiRelationshipTypeID = C.tiID_Lien_CoSouscripteur
        LEFT JOIN tblCONV_PreferenceSuivi Prf ON PRF.iID_Preference_Suivi = S.iID_Preference_Suivi --Preference suivi
        LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID AND PS.DateProfilInvestisseur = (
            SELECT    
                MAX(PSM.DateProfilInvestisseur)
            FROM tblCONV_ProfilSouscripteur PSM
            WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
                AND PSM.DateProfilInvestisseur <= GETDATE()
            )
        LEFT JOIN tblGENE_PortailAuthentification PAS ON PAS.iUserId = S.SubscriberID 
        LEFT JOIN tblGENE_PortailAuthentification PAB ON PAB.iUserId = B.BeneficiaryID
        LEFT JOIN tblGENE_TypesParametre GTPB on GTPB.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE'
        LEFT JOIN tblGENE_Parametres GPB ON GTPB.iID_Type_Parametre = GPB.iID_Type_Parametre
        LEFT JOIN tblGENE_TypesParametre GTPS on GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR'
        LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
        LEFT JOIN (
            SELECT r.iID_Convention_Destination
            from tblOPER_OperationsRIO r
            WHERE r.OperTypeID IN ('RIO', 'RIM')
            AND r.bRIO_QuiAnnule = 0
            GROUP BY r.iID_Convention_Destination
                )FBU ON C.ConventionID = FBU.iID_Convention_Destination

        WHERE S.SubscriberID = @MatrixID
        ORDER BY
            SH.LastName,
            SH.FirstName,
            C.ConventionNo,
            BH.LastName,
            BH.FirstName
    END -- IF (@MatrixType = 'SUB')
    ELSE IF @MatrixType = 'BNF' -- Bénéficaire
    BEGIN
        DECLARE 
            @RepID INTEGER

        SET @RepID = 0

        -- Va chercher le repID si l'usager est une représentant
        SELECT 
            @RepID = R.RepID
        FROM Mo_Connect C
        JOIN Un_Rep R ON R.RepID = C.UserID
        WHERE C.ConnectID = @ConnectID

        -- Création de tables temporaires pour filtrer les données pour les usagers représentants
        CREATE TABLE #tRep (RepID INTEGER PRIMARY KEY)
        CREATE TABLE #tConvention ( BeneficiaryID INTEGER NOT NULL,
                                    ConventionID INTEGER NOT NULL)
            --CONSTRAINT PK_#tConvention PRIMARY KEY (BeneficiaryID, ConventionID))  --2011-03-01 : JFG : Cause des problèmes dans un contexte multi-usagers

        INSERT #tRep
            EXECUTE SL_UN_BossOfRep @RepID

        INSERT #tConvention
            SELECT DISTINCT
                C.BeneficiaryID,
                C.ConventionID
            FROM dbo.Un_Convention C
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            JOIN #tRep B ON S.RepID = B.RepID OR @RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
            WHERE C.BeneficiaryID = @MatrixID

        DROP TABLE #tRep

        SELECT
            S.SubscriberID,
            S.RepID,
            /*SRepName = 
                CASE 
                    WHEN R.HumanID IS NULL THEN ''
                    ELSE R.LastName + ', ' + R.FirstName
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            SRepName = CASE WHEN R_Rep.BusinessEnd IS NULL THEN 
                    CASE WHEN R.HumanID IS NULL THEN '' ELSE R.LastName + ', ' + R.FirstName + ' (' + R_Rep.Repcode + ')' END
                   ELSE CASE WHEN R.HumanID IS NULL THEN '' ELSE R.LastName + ', ' + R.FirstName + ' (' + R_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            S.ScholarshipLevelID,
            S.AnnualIncome,
            S.StateID,
            S.SemiAnnualStatement,
            SFirstName = SH.FirstName,
            SOrigName = SH.OrigName,
            SLastName = SH.LastName,
            SvcNIP = ISNULL(SH.vcNIP, ''),
            SCompanyName = SH.CompanyName,
            SSexID = SH.SexID,
            SAdrID = SH.AdrID,
            SBirthDate = SH.BirthDate,
            SDeathDate = SH.DeathDate,
            SLangID = SH.LangID,
            SCivilID = SH.CivilID,
            SCourtesyTitle = SH.CourtesyTitle,
            SUsingSocialNumber = SH.UsingSocialNumber,
            SSharePersonalInfo = SH.SharePersonalInfo,
            SMarketingMaterial = SH.MarketingMaterial,
            SIsCompany = SH.IsCompany,
            SSocialNumber = SH.SocialNumber,
            SDriverLicenseNo = SH.DriverLicenseNo,
            SWebSite = SH.WebSite,
            SResidID = SH.ResidID,
            SInForce = SA.InForce,
            SAdrTypeID = SA.AdrTypeID,
            SSourceID = SA.SourceID,
            SAddress = SA.Address,
            SCity = SA.City,
            SStateName = SA.StateName,
            SCountryID = SA.CountryID,
            SZipCode = SA.ZipCode,
            SPhone1 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone1, SA.CountryID),
            SPhone2 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone2, SA.CountryID),
            SFax = dbo.FN_CRQ_FormatPhoneNo(SA.Fax, SA.CountryID),
            SMobile = dbo.FN_CRQ_FormatPhoneNo(SA.Mobile, SA.CountryID),
            SWattLine = dbo.FN_CRQ_FormatPhoneNo(SA.WattLine, SA.CountryID),
            SOtherTel = dbo.FN_CRQ_FormatPhoneNo(SA.OtherTel, SA.CountryID),
            SPager = dbo.FN_CRQ_FormatPhoneNo(SA.Pager, SA.CountryID),
            SEMail = SA.EMail,
            tiSubsCESPState = S.tiCESPState, -- État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)
            Spouse = ISNULL(S.Spouse,''),
            Contact1 = ISNULL(S.Contact1,''),
            Contact2 = ISNULL(S.Contact2,''),
            Contact1Phone = ISNULL(S.Contact1Phone,''),
            Contact2Phone = ISNULL(S.Contact2Phone,''),
            SNEQ = ISNULL(SH.StateCompanyNo,''),
            bSouscripteur_Desire_Releve_Elect = ISNULL(S.bReleve_Papier,0), 
            bSouscripteur_Accepte_Publipostage = SH.bHumain_Accepte_Publipostage,
            B.BeneficiaryID,
            B.GovernmentGrantForm,
            B.BirthCertificate,
            B.PersonalInfo,
            B.ProgramID,
            B.ProgramLength,
            B.ProgramYear,
            B.SchoolReport,
            B.RegistrationProof,
            B.StudyStart,
            B.CaseOfJanuary,
            B.EligibilityQty,
            B.CollegeID,
            bBeneficiaryAddressLost = B.bAddressLost,
            tiPCGType =
                CASE 
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 0 THEN 0
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 1 THEN 1
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 1 THEN 2
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 0 THEN 3
                END, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise-Souscripteur, 3=Entreprise)
            B.vcPCGFirstName, -- Prénom du principal responsable s’il s’agit d’un souscripteur ou d’une personne. Nom de l’entreprise principal responsable dans l’autre cas.
            B.vcPCGLastName, -- Nom du principal responsable s’il s’agit d’un souscripteur ou d’une personne.
            B.vcPCGSINOrEN, -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
            bBeneficiaire_Accepte_Publipostage = BH.bHumain_Accepte_Publipostage,
            tiBenefCESPState = B.tiCESPState,
            Co.CollegeTypeID,
            B.EligibilityConditionID,
            Co.CollegeCode,
            CollegeName = CoCo.CompanyName,
            Prog.ProgramDesc,
            BFirstName = BH.FirstName,
            BOrigName = BH.OrigName,
            BInitial = BH.Initial,
            BLastName = BH.LastName,
            BvcNIP = ISNULL(BH.vcNIP, ''),
            BCompanyName = BH.CompanyName,
            BSexID = BH.SexID,
            BAdrID = BH.AdrID,
            BBirthDate = BH.BirthDate,
            BDeathDate = BH.DeathDate,
            BLangID = BH.LangID,
            BCivilID = BH.CivilID,
            BCourtesyTitle = BH.CourtesyTitle,
            BUsingSocialNumber = BH.UsingSocialNumber,
            BSharePersonalInfo = BH.SharePersonalInfo,
            BMarketingMaterial = BH.MarketingMaterial,
            BIsCompany = BH.IsCompany,
            BSocialNumber = BH.SocialNumber,
            BDriverLicenseNo = BH.DriverLicenseNo,
            BWebSite = BH.WebSite,
            BResidID = BH.ResidID,
            BNEQ = ISNULL(BH.StateCompanyNo,''),
            BInForce = BA.InForce,
            BAdrTypeID = BA.AdrTypeID,
            BSourceID = BA.SourceID,
            BAddress = BA.Address,
            BCity = BA.City,
            BStateName = BA.StateName,
            BCountryID = BA.CountryID,
            BZipCode = BA.ZipCode,
            BPhone1 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone1, BA.CountryID),
            BPhone2 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone2, BA.CountryID),
            BFax = dbo.FN_CRQ_FormatPhoneNo(BA.Fax, BA.CountryID),
            BMobile = dbo.FN_CRQ_FormatPhoneNo(BA.Mobile, BA.CountryID),
            BWattLine = dbo.FN_CRQ_FormatPhoneNo(BA.WattLine, BA.CountryID),
            BOtherTel = dbo.FN_CRQ_FormatPhoneNo(BA.OtherTel, BA.CountryID),
            BPager = dbo.FN_CRQ_FormatPhoneNo(BA.Pager, BA.CountryID),
            BEMail = BA.EMail,
            C.ConventionID,
            C.ConventionNo,
            C.YearQualif,
            C.tiMaximisationREEE,
            PmtDate = C.FirstPmtDate,
            C.PmtTypeID,
            C.tiRelationshipTypeID,
            RT.vcRelationshipType,
            C.GovernmentRegDate,
            C.ScholarshipYear,
            C.ScholarshipEntryID,
            C.dtRegEndDateAdjust,
            dtConvInforceDateTIN = C.dtInforceDateTIN,
            C.CoSubscriberID,
            CPlanID = PC.PlanID,
            CPlanTypeID = PC.PlanTypeID,
            CPlanDesc = PC.PlanDesc,
            C.bTuteur_Desire_Releve_Elect,
            U.UnitID,
            U.UnitQty,
            U.InForceDate,
            U.SignatureDate,
            U.TerminatedDate,
            U.IntReimbDate,
            U.ActivationConnectID,
            U.ValidationConnectID,
            U.BenefInsurID,
            U.WantSubscriberInsurance,
            URepID = U.RepID,
            /*URepName = 
                CASE ISNULL(U.RepID,0) 
                    WHEN 0 THEN '' 
                ELSE UR.LastName + ', ' + UR.FirstName 
                END, 
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepName = CASE WHEN UR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            URepResponsableID = U.RepResponsableID,
            U.PmtEndConnectID,
            U.IntReimbDateAdjust,
            /*URepResponsableName = 
                CASE ISNULL(U.RepResponsableID,0) 
                    WHEN 0 THEN '' 
                ELSE URR.LastName + ', ' + URR.FirstName 
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepResponsableName = CASE WHEN URR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            U.StopRepComConnectID,
            U.SubscribeAmountAjustment,
            U.LastDepositForDoc,
            U.dtCotisationEndDateAdjust,
            U.dtInforceDateTIN,
            U.iSous_Cat_ID,
            MCD.YearQty,
            M.ModalID,
            M.ModalDate,
            M.PmtByYearID,
            M.PmtQty,
            M.PmtRate,
            M.SubscriberInsuranceRate,
            M.BenefAgeOnBegining,
            FeeByUnit = CASE WHEN FBU.iID_Convention_Destination IS NULL THEN  M.FeeByUnit ELSE 0 END,
            M.FeeSplitByUnit,
            M.FeeRefundable,
            P.tiAgeQualif,
            M.BusinessBonusToPay,
            BI.BenefInsurDate,
            BI.BenefInsurFaceValue,
            BI.BenefInsurPmtByYear,
            BI.BenefInsurRate,
            P.PlanID,
            P.PlanDesc,
            P.PlanTypeID,
            P.IntReimbAge,
            CA.BankID,
            CA.AccountName,
            CA.TransitNo,
            BK.BankTransit,
            BK.BankName,
            BK.BankTypeName,
            BK.BankTypeCode,
            ConventionBreaking = ISNULL(Bkg.ConventionID,0),
            UnitHoldPayment = ISNULL(uhp.UnitID,0),
            StateTaxPct = ISNULL(St.StateTaxPct,0),
            FirstPmtDate = Ct.OperDate,
            Cotisation = ISNULL(Ct.Cotisation, 0),
            Fee = ISNULL(Ct.Fee, 0),
            CapitalInterestAmount = ISNULL(CI.CapitalInterestAmount, 0),
            GrantInterestAmount = ISNULL(CG.GrantInterestAmount, 0),
            AvailableFeeAmount = ISNULL(CF.AvailableFeeAmount, 0),
            AutomaticDepositCount = ISNULL(AD.AutomaticDepositCount, 0),
            CoSubscriberName = 
                CASE 
                    WHEN ISNULL(C.CoSubscriberID, 0) = 0 THEN '' 
                    WHEN SHC.IsCompany = 1 THEN SHC.LastName
                ELSE SHC.LastName + ', ' + SHC.FirstName 
                END,
            NbNSF = ISNULL(NSF.NbNSF,0),
            SS.SaleSourceID, --point 718
            SS.SaleSourceDesc, --point 718
            bIsContestWinner = ISNULL(SS.bIsContestWinner,0),
            TotalCapitalInsured = 
                CASE 
                    WHEN ISNULL(TC.TotalCapitalInsured,0) > 0 THEN TC.TotalCapitalInsured 
                ELSE 0 
                END, -- point#729
            CESGInForceDate = GGI.InForceDate, -- #0768-05
            CS.ConventionStateID,
            CS.ConventionStateName,
            US.UnitStateID,
            US.UnitStateName,
            AutoMonthTheoricAmount = 
                CASE ISNULL(C.PmtTypeID, '') 
                    WHEN 'AUT' THEN ISNULL(AMT.MonthTheoricAmount,0) 
                END, -- Valeur retournée seulement si paiement automatique
            BirthLangID = ISNULL(WorldLanguageCodeID,''),
            BirthLangName = ISNULL(WorldLanguage,''),
            S.AddressLost,
            UDirName = 
                CASE ISNULL(UDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HUDIR.LastName + ', ' + HUDIR.FirstName 
                END,
            SDirName = 
                CASE ISNULL(SDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HSDIR.LastName + ', ' + HSDIR.FirstName 
                END,
            C.bSendToCESP, -- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
            fCESG = ISNULL(GG.fCESG,0), -- Solde du compte de SCEE de la convention.
            fACESG = ISNULL(GG.fACESG,0), -- Solde du compte de SCEE+ de la convention.
            fCLB = ISNULL(GG.fCLB,0), -- Solde du compte de BEC de la convention.
            C.bCESGRequested, -- SCEE voulue (1) ou non (2)
            C.bACESGRequested, -- SCEE+ voulue (1) ou non (2)
            C.bCLBRequested, -- BEC voulu (1) ou non (2)
            C.tiCESPState, -- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
            DiplomaTextID = 9999, -- DT.DiplomaTextID,  -- ID unique du texte du diplôme        -- 2015-07-29
            DiplomaText = ISNULL(C.TexteDiplome, ''), -- DT.DiplomaText, -- Texte du diplôme        -- 2015-07-29
            B.iTutorID, -- ID du tuteur, correspond au HumanID.
            B.bTutorIsSubscriber, -- Si le Tuteur est un souscripteur ou non
            TvcEN = Tu.vcEN, -- Numéro d’entreprise, si le tuteur en est une.
            TFirstName = TuH.FirstName, -- Prénom du tuteur
            TOrigName = TuH.OrigName, -- Nom à la naissance
            TInitial = TuH.Initial, -- Initial (Jr, Sr, etc.)
            TLastName = TuH.LastName, -- Nom
            TvcNIP = ISNULL(TuH.vcNIP, ''),
            TBirthDate = TuH.BirthDate, -- Date de naissance
            TDeathDate = TuH.DeathDate, -- Date du décès
            TSexID = TuH.SexID, -- Sexe (code)
            TLangID = TuH.LangID, -- Langue (code)
            TCivilID = TuH.CivilID, -- Statut civil (code)
            TSocialNumber = TuH.SocialNumber, -- Numéro d’assurance sociale
            TResidID = TuH.ResidID, -- Pays de résidence (code)
            TDriverLicenseNo = TuH.DriverLicenseNo, -- Numéro de permis
            TWebSite = TuH.WebSite, -- Site internet
            TCourtesyTitle = TuH.CourtesyTitle, -- Titre de courtoisie (Docteur, Professeur, etc.)
            TUsingSocialNumber = TuH.UsingSocialNumber, -- Droit d’utiliser le NAS.
            TSharePersonalInfo = TuH.SharePersonalInfo, -- Droit de partager les informations personnelles
            TMarketingMaterial = TuH.MarketingMaterial, -- Veux recevoir le matériel publicitaire.
            TIsCompany = TuH.IsCompany, -- Compagny ou humain
            TInForce = TuA.InForce, -- Date d’entrée en vigueur de l’adresse.
            TAdrTypeID = TuA.AdrTypeID, -- Type d’adresse (H = humain, C = Compagnie)
            TSourceID = TuA.SourceID, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
            TAddress = TuA.Address, -- # civique, rue et # d’appartement.
            TCity = TuA.City, -- Ville
            TStateName = TuA.StateName, -- Province
            TCountryID = TuA.CountryID, -- Pays (code)
            TZipCode = TuA.ZipCode, -- Code postal
            TPhone1 = TuA.Phone1, -- Tél. résidence
            TPhone2 = TuA.Phone2, -- Tél. bureau
            TFax = TuA.Fax, -- Fax
            TMobile = TuA.Mobile, -- Tél. cellulaire
            TWattLine = TuA.WattLine, -- Tél. sans frais
            TOtherTel = TuA.OtherTel, -- Autre téléphone.
            TPager = TuA.Pager, -- Paget
            TEmail = TuA.Email, -- Courriel
            fAvailableUnitQty = ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0),            
            ConventionIDInd=C2.ConventionID, --Id convention individuelle RIO
            ConventionNoInd=C2.ConventionNo, --No convnetion individuelle RIO                    
            PaysOrigine = ISNULL(Corg.CountryName, ''), --Pays d'origine            
            PreferenceSuiviID = ISNULL(S.iID_Preference_Suivi, 0), --Preference suivi
            NoPersonnesaCharge=ISNULL(PS.tiNB_Personnes_A_Charge,0), --Ajout de la table tblCONV_ProfilSouscripteur
            ConnaisancePlacementID=ISNULL(PS.iID_Connaissance_Placements,0),
            RevenuFamilialID=ISNULL(PS.iID_Revenu_Familial,0),
            DepassementBaremeID=ISNULL(PS.iID_Depassement_Bareme,0),
            IdentiteSouscripteurID=ISNULL(S.iID_Identite_Souscripteur,0),
            ObjectifInvestissementLigne1ID=ISNULL(PS.iID_ObjectifInvestissementLigne1,0),
            ObjectifInvestissementLigne2ID=ISNULL(PS.iID_ObjectifInvestissementLigne2,0),
            ObjectifInvestissementLigne3ID=ISNULL(PS.iID_ObjectifInvestissementLigne3,0),
            IdentiteDescription=ISNULL(S.vcIdentiteVerifieeDescription,''),
            AutorisationResiliation=ISNULL(S.bAutorisation_Resiliation,0),
            DepassementJustification=ISNULL(PS.vcDepassementbaremeJustification,''),
            EstimationCoutEtudesID = ISNULL(PS.iID_Estimation_Cout_Etudes, 0),
            EstimationValeurNetteMenageID = ISNULL(PS.iID_Estimation_Valeur_Nette_Menage, 0), 
            DestinationRemboursementID=ISNULL(C.iID_Destinataire_Remboursement, 0), --L'ID du Destination remboursement
            DestinationRemboursementAutre=ISNULL(C.vcDestinataire_Remboursement_Autre, ''), --Destination remboursement autre
            DateduProspectus=ISNULL(C.dtDateProspectus, ''), --Date du prospectus
            SouscripteurDesireIQEE=ISNULL(C.bSouscripteur_Desire_IQEE, 0), --Souscripteur desire IQEE
            C.tiID_Lien_CoSouscripteur,
            LienCoSouscripteur=ISNULL(LC.vcRelationshipType,''),
            C.iSous_Cat_ID_Resp_Prelevement,
            IDNiveauEtudeMere        = ISNULL(PS.iIDNiveauEtudeMere,    0),            -- 2010-01-06 : JFG :Modification des champs du profil souscripteur
            IDNiveauEtudePere        = ISNULL(PS.iIDNiveauEtudePere, 0),
            IDNiveauEtudeTuteur        = ISNULL(PS.iIDNiveauEtudeTuteur, 0),
            IDImportanceEtude        = ISNULL(PS.iIDImportanceEtude, 0),
            IDEpargneEtudeEnCours    = ISNULL(PS.iIDEpargneEtudeEnCours, 0),
            IDContributionFinanciereParent = ISNULL(PS.iIDContributionFinanciereParent,    0),
            IDConditionEligibleBenef = ISNULL(B.EligibilityConditionID, ''),
            R_Rep.iNumeroBDNI,
            C.bFormulaireRecu,
            C.dtRegStartDate,
            C.bSouscripteur_Desire_IQEE,
            IQEE        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            IQEEMaj        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            ConventionTypeInd            = S1.OperTypeID,                -- Type de la convention individuelle (RIO, RIM ou TRI)    
            vcOccupation                    = ISNULL(SH.vcOccupation, ''),                        -- Occupation de l'humain    
            vcEmployeur                        = ISNULL(SH.vcEmployeur, ''),                        -- Employeur de l'humain    
            tiNbAnneesService                = ISNULL(SH.tiNbAnneesService, ''),                    -- Nombre d'années de service    
            bRapport_Annuel_Direction        = ISNULL(S.bRapport_Annuel_Direction, 0),            -- Désire le rapport annuel de la direction
            bEtats_Financiers_Annuels        = ISNULL(S.bEtats_Financiers_Annuels, 0),            -- Désire les états financiers annuels    
            vcJustifObjectifsInvestissement    = ISNULL(PS.vcJustifObjectifsInvestissement, ''),    -- Justification du choix des objectifs d'investissement
            bEtats_Financiers_Semestriels    = ISNULL(S.bEtats_Financiers_Semestriels, 0),        -- Désire les états financiers semestriels        
            C.vcCommInstrSpec,
            iIDJustificationConvIncomplete = ISNULL(C.iID_Justification_Conv_Incomplete, 0),
--            bAImprimer                       = ISNULL(C.bAImprimer, 0),
            bStatutPortailSubscriber       = CASE when PAS.iUserId is NULL THEN 0 ELSE 1 END,
            bStatutPortailBeneficiary       = CASE when PAB.iUserId is NULL THEN 0 ELSE 1 END,
            DateRQ = dbo.fnIQEE_ObtenirDateEnregistrementRQ(C.ConventionID), 
              DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL), 
            DateFinRegimeOriginale = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'T', NULL),
            DateEntreeVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
            ,bConsentement_Souscripteur = CASE WHEN ISNULL(PAS.iEtat, 0) = 5 THEN CAST('1' AS bit) ELSE cast('0' AS bit) END 
            ,bConsentement_Beneficiaire = ISNULL(B.bReleve_Papier,0)  
            ,vcDossierBeneficiaire = GPB.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(BH.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(BH.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(BH.firstname)),' ','_') + '_' + cast(BH.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,vcDossierSouscripteur = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(sh.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(sh.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(sh.firstname)),' ','_') + '_' + cast(sh.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,ToleranceRisqueID=ISNULL(PS.iID_Tolerance_Risque,0)
        FROM dbo.Un_Beneficiary B
        JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
        LEFT JOIN dbo.Mo_Adr BA ON BA.AdrID = BH.AdrID
        LEFT JOIN #tConvention TBC ON TBC.BeneficiaryID = B.BeneficiaryID -- Filtre des usagers représentants 
        LEFT JOIN dbo.Un_Convention C ON C.ConventionID = TBC.ConventionID
        LEFT JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID
        LEFT JOIN (-- Date de vigueur enregistrée à la SCÉÉ #0768-07
            SELECT 
                G.ConventionID,
                InForceDate = MIN(G.dtTransaction) 
            FROM Un_CESP100 G
            LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
            JOIN (-- Retourne la plus grande date de fichier scee envoyé par convention
                SELECT 
                    G.ConventionID,
                    dtCESPSendFile = MAX(ISNULL(S.dtCESPSendFile, @Today))
                FROM Un_CESP100 G
                JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
                LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
                WHERE C.BeneficiaryID = @MatrixID
                GROUP BY G.ConventionID
                ) V ON V.ConventionID = G.ConventionID AND ISNULL(S.dtCESPSendFile, @Today) = V.dtCESPSendFile
            GROUP BY G.ConventionID
            ) GGI ON GGI.ConventionID = C.ConventionID
        LEFT JOIN dbo.Mo_Human SHC ON SHC.HumanID = C.CoSubscriberID
        LEFT JOIN (-- Retourne la somme des intérêts sur montant souscrit par convention
            SELECT
                CO.ConventionID,
                CapitalInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
              AND CO.ConventionOperTypeID = 'INM'
            GROUP BY CO.ConventionID
            ) CI ON CI.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des intérêts sur subvention par convention
            SELECT
                CO.ConventionID,
                GrantInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
              AND CHARINDEX(','+CO.ConventionOperTypeID+',',@vcCONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION) > 0
            GROUP BY CO.ConventionID
            ) CG ON CG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des frais disponibles par convention
            SELECT
                CO.ConventionID,
                AvailableFeeAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
              AND CO.ConventionOperTypeID = 'FDI'
            GROUP BY CO.ConventionID
            ) CF ON CF.ConventionID = C.ConventionID
        LEFT JOIN Un_Plan PC ON PC.PlanID = C.PlanID
        LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
        LEFT JOIN Un_Modal M ON M.ModalID = U.ModalID
        LEFT JOIN Un_Plan P ON P.PlanID = M.PlanID
        LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
        LEFT JOIN dbo.Mo_Human SH ON SH.HumanID = S.SubscriberID
        LEFT JOIN ( -- point#729                                                                                       
            SELECT 
                V1.SubscriberID, 
                TotalCapitalInsured = SubscribAmount - ISNULL(AmountToDate,0)
            FROM (-- Retourne le total des montants versés par souscripteur
                SELECT 
                    C.SubscriberID, 
                    SubscribAmount = SUM(ROUND(M.PmtRate * U.UnitQty, 2) * PmtQty)
                FROM dbo.Un_Convention C                      
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                WHERE C.BeneficiaryID = @MatrixID
                  AND U.WantSubscriberInsurance <> 0                                                           
                  AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID 
                ) V1
            LEFT JOIN (-- Retourne les cotisations versées jusqu'à présent par souscripteurs
                SELECT 
                    C.SubscriberID, 
                    AmountToDate = SUM(Co.Cotisation + Co.Fee)
                FROM dbo.Un_Convention C                      
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                WHERE C.BeneficiaryID = @MatrixID
                  AND U.WantSubscriberInsurance <> 0
                  AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID
                ) V2 ON V1.SubscriberID = V2.SubscriberID
            ) TC ON TC.SubscriberID = S.SubscriberID
        LEFT JOIN dbo.Mo_Adr SA ON SA.AdrID = SH.AdrID
        --LEFT JOIN dbo.Mo_Human R ON R.HumanID = S.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep R_Rep ON R_Rep.RepID = S.RepID
        LEFT JOIN dbo.Mo_Human R ON R.HumanID = R_Rep.RepID
        --LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = U.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep UR_Rep ON UR_Rep.RepID = U.RepID
        LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = UR_Rep.RepID
        --LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = U.RepResponsableID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep URR_Rep ON URR_Rep.RepID = U.RepResponsableID
        LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = URR_Rep.RepID
        LEFT JOIN (-- Retourne le total des cotisations et de frais ainsi que la plus petite date d'opération par unités
            SELECT
                Ct.UnitID,
                OperDate = MIN(O.OperDate),
                FEE = SUM(Ct.Fee),
                Cotisation = SUM(Ct.Cotisation)
            FROM Un_Cotisation Ct
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN Un_Oper O ON O.OperID = Ct.OperID
            LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
            WHERE C.BeneficiaryID = @MatrixID
                AND(    ( O.OperTypeID = 'CPA' 
                         AND ISNULL(OBF.OperID, 0) > 0
                        )
                    OR O.OperDate < = GETDATE()
                    )
            GROUP BY Ct.UnitID
            ) Ct ON Ct.UnitID = U.UnitID
        LEFT JOIN (-- Sert à la détection d'un arrêt de paiement sur le groupe d'unité
            SELECT DISTINCT 
                H.UnitID
            FROM Un_UnitHoldPayment H
            JOIN dbo.Un_Unit U ON U.UnitID = H.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
                AND H.StartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(H.EndDate,0) <= 0
                        OR H.EndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) UHP ON UHP.UnitID = U.UnitID                    
        LEFT JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne l'info des banques
            SELECT DISTINCT
                B.BankID,
                B.BankTransit,
                BankName = C.CompanyName,
                BT.BankTypeName,
                BT.BankTypeCode
            FROM Mo_Bank B
            JOIN Mo_Company C ON C.CompanyID = B.BankID
            JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
            JOIN Un_ConventionAccount CA ON CA.BankID = B.BankID
            JOIN dbo.Un_Convention Co ON CA.ConventionID = Co.ConventionID
            WHERE Co.BeneficiaryID = @MatrixID
            ) BK ON BK.BankID = CA.BankID    
        LEFT JOIN Un_Program Prog ON Prog.ProgramID = B.ProgramID
        LEFT JOIN Un_College Co ON Co.CollegeID = B.CollegeID
        LEFT JOIN Mo_Company CoCo ON CoCo.CompanyID = Co.CollegeID
        LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
        LEFT JOIN Mo_State St ON St.StateID = S.StateID
        LEFT JOIN (-- Retourne les conventions en arrêt de paiement
            SELECT DISTINCT 
                B.ConventionID
            FROM Un_Breaking B
            JOIN dbo.Un_Convention C ON C.ConventionID = B.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
                AND B.BreakingStartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(B.BreakingEndDate,0) <= 0
                        OR B.BreakingEndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) BKG ON BKG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne le nombre de dépôts par unité
            SELECT
                A.UnitID,
                AutomaticDepositCount = COUNT(A.AutomaticDepositID)
            FROM Un_AutomaticDeposit A
            JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
                AND    ( dbo.FN_CRQ_DateNoTime(GETDATE()) BETWEEN A.StartDate AND A.EndDate
                         OR    ( dbo.FN_CRQ_DateNoTime(GETDATE()) >= A.StartDate 
                                AND ISNULL(A.EndDate,0) < 2
                                )
                        )
            GROUP BY A.UnitID
            ) AD ON AD.UnitID = U.UnitID
        LEFT JOIN (-- Retourne le nombre de nsf par convention    
            SELECT
                U.ConventionID,
                NbNSF = COUNT(DISTINCT O.OperID)
            FROM Mo_BankReturnLink R
            JOIN Un_Oper O ON O.OperID = R.BankReturnCodeID
            JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
              AND R.BankReturnTypeID = '901'
            GROUP BY U.ConventionID        
            ) NSF ON NSF.ConventionID = C.ConventionID
        LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
        LEFT JOIN (-- 10.23.1 (2.2) : Retrouve l'état actuel d'une convention
            SELECT 
                T.ConventionID,
                CS.ConventionStateID,
                CS.ConventionStateName
            FROM (-- Retourne la plus grande date de début d'un état par convention
                SELECT 
                    S.ConventionID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_ConventionConventionState S
                JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
                WHERE C.BeneficiaryID = @MatrixID
                  AND S.StartDate <= GETDATE()
                GROUP BY S.ConventionID
                ) T
            JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID    AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
            JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
            ) CS ON C.ConventionID = CS.ConventionID
        LEFT JOIN (-- 10.23.1 (3.2) : Retrouve l'état actuel d'un groupe d'unités
            SELECT 
                T.UnitID,
                US.UnitStateID,
                US.UnitStateName
            FROM (-- Retourne la plus grande date de début d'un état par unité
                SELECT 
                    S.UnitID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_UnitUnitState S
                JOIN dbo.Un_Unit U ON U.UnitID = S.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                WHERE C.BeneficiaryID = @MatrixID
                  AND S.StartDate <= GETDATE()
                GROUP BY S.UnitID
                ) T
            JOIN Un_UnitUnitState UUS ON T.UnitID = UUS.UnitID AND T.MaxDate = UUS.StartDate -- Retrouve l'état correspondant à la plus grande date par unité
            JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID -- Pour retrouver la description de l'état
            ) US ON U.UnitID = US.UnitID
        LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
            SELECT
                U.ConventionID,
                MonthTheoricAmount = 
                    SUM(
                        ROUND(M.PmtRate * U.UnitQty,2) + -- Cotisation et frais
                        dbo.FN_CRQ_TaxRounding
                            ((    CASE U.WantSubscriberInsurance -- Assurance souscripteur
                                    WHEN 0 THEN 0
                                ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
                                END +
                                ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
                            (1+ISNULL(St.StateTaxPct,0)))) -- Taxes
            FROM dbo.Un_Unit U
            JOIN Un_Modal M ON U.ModalID = M.ModalID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            LEFT JOIN Mo_State St ON St.StateID = S.StateID
            LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
            LEFT JOIN (
                SELECT
                    U.UnitID,
                    CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
                FROM dbo.Un_Unit U
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
                WHERE C.BeneficiaryID = @MatrixID
                GROUP BY U.UnitID
                ) Ct ON U.UnitID = Ct.UnitID
            WHERE C.BeneficiaryID = @MatrixID
              AND M.PmtByYearID = 12
              AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
            GROUP BY U.ConventionID
            ) AMT ON C.ConventionID = AMT.ConventionID 
        LEFT JOIN CRQ_WorldLang W ON S.BirthLangID = W.WorldLanguageCodeID
        LEFT JOIN (
            SELECT
                M.UnitID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    U.UnitID,
                    U.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Unit U
                JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
                JOIN Un_RepBossHist RBH ON (RBH.RepID = U.RepID) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
                JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
                JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
                WHERE C.BeneficiaryID = @MatrixID
                GROUP BY U.UnitID, U.RepID
                ) M
            JOIN dbo.Un_Unit U ON (U.UnitID = M.UnitID)
            JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
            JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
            WHERE C.BeneficiaryID = @MatrixID
            GROUP BY M.UnitID
            ) UDIR ON (UDIR.UnitID = U.UnitID)
        LEFT JOIN dbo.Mo_Human HUDIR ON (HUDIR.HumanID = UDIR.BossID)
        LEFT JOIN (
            SELECT
                M.SubscriberID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    S.SubscriberID,
                    S.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Subscriber S
                JOIN dbo.Un_Convention C ON (C.SubscriberID = S.SubscriberID)
                JOIN Un_RepBossHist RBH ON (RBH.RepID = S.RepID) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
                JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
                JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)
                WHERE C.BeneficiaryID = @MatrixID
                GROUP BY S.SubscriberID, S.RepID
                ) M
            JOIN dbo.Un_Subscriber S ON (S.SubscriberID = M.SubscriberID)
            JOIN dbo.Un_Convention C ON (C.SubscriberID = S.SubscriberID)
            JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
            WHERE C.BeneficiaryID = @MatrixID
            GROUP BY M.SubscriberID
            ) SDIR ON (SDIR.SubscriberID = S.SubscriberID)
        LEFT JOIN dbo.Mo_Human HSDIR ON (HSDIR.HumanID = SDIR.BossID)
        LEFT JOIN (
            SELECT 
                CE.ConventionID,
                fCESG = SUM(CE.fCESG),
                fACESG = SUM(CE.fACESG),
                fCLB = SUM(CE.fCLB)
            FROM Un_CESP CE
            JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
            GROUP BY CE.ConventionID
            ) GG ON GG.ConventionID = C.ConventionID
        --LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID
        LEFT JOIN Un_Tutor Tu ON Tu.iTutorID = B.iTutorID AND B.bTutorIsSubscriber = 0
        LEFT JOIN dbo.Mo_Human TuH ON TuH.HumanID = B.iTutorID
        LEFT JOIN dbo.Mo_Adr TuA ON TuA.AdrID = TuH.AdrID
        LEFT JOIN ( -- Unité résiliés
                SELECT 
                    C.ConventionID, 
                    UnitRes = SUM(UR.UnitQty)
                FROM Un_UnitReduction UR
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                WHERE C.BeneficiaryID = @MatrixID
                GROUP BY C.ConventionID) SR ON SR.ConventionID = C.ConventionID
        LEFT JOIN ( -- Unité utilisés
                SELECT 
                    C.ConventionID, 
                    UnitUse = SUM(A.fUnitQtyUse)
                FROM Un_UnitReduction UR
                JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID            
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                WHERE C.BeneficiaryID = @MatrixID
                GROUP BY C.ConventionID) SU ON SU.ConventionID = C.ConventionID
        LEFT JOIN @tUn_MaxConvDepositDateCfg MCD ON U.InForceDate BETWEEN MCD.dtStart AND MCD.dtEnd
        LEFT JOIN (SELECT iID_Convention_Source,iID_Convention_Destination = min(iID_Convention_Destination), iID_Unite_Source, TOPER.OperTypeID
                    FROM tblOPER_OperationsRIO TOPER 
                    WHERE (TOPER.bRIO_ANNULEE = 0 AND TOPER.bRIO_QUIANNULE = 0)
                    GROUP BY iID_Convention_Source, iID_Unite_Source, TOPER.OperTypeID) AS S1 ON S1.iID_Convention_Source = C.ConventionID  AND S1.iID_Unite_Source = U.UnitID
        LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = S1.iID_Convention_Destination
        LEFT JOIN Mo_Country Corg ON Corg.CountryID = SH.cID_Pays_Origine --Pays d'origine
        LEFT JOIN Un_RelationshipType LC ON LC.tiRelationshipTypeID = C.tiID_Lien_CoSouscripteur
        LEFT JOIN tblCONV_PreferenceSuivi Prf ON PRF.iID_Preference_Suivi = S.iID_Preference_Suivi --Preference suivi
        LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID AND PS.DateProfilInvestisseur = (
            SELECT    
                MAX(PSM.DateProfilInvestisseur)
            FROM tblCONV_ProfilSouscripteur PSM
            WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
                AND PSM.DateProfilInvestisseur <= GETDATE()
            )
        LEFT JOIN tblGENE_PortailAuthentification PAS ON PAS.iUserId = S.SubscriberID 
        LEFT JOIN tblGENE_PortailAuthentification PAB ON PAB.iUserId = B.BeneficiaryID
        LEFT JOIN tblGENE_TypesParametre GTPB on GTPB.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE'
        LEFT JOIN tblGENE_Parametres GPB ON GTPB.iID_Type_Parametre = GPB.iID_Type_Parametre
        LEFT JOIN tblGENE_TypesParametre GTPS on GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR'
        LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
        LEFT JOIN (
            SELECT r.iID_Convention_Destination
            from tblOPER_OperationsRIO r
            WHERE r.OperTypeID IN ('RIO', 'RIM')
            AND r.bRIO_QuiAnnule = 0
            GROUP BY r.iID_Convention_Destination
                )FBU ON C.ConventionID = FBU.iID_Convention_Destination
        WHERE B.BeneficiaryID = @MatrixID
        ORDER BY
            BH.LastName,
            BH.FirstName,
            C.ConventionNo,
            SH.LastName,
            SH.FirstName

        DROP TABLE #tConvention

    END -- ELSE IF (@MatrixType = 'BNF')
    ELSE IF @MatrixType = 'CON' -- Convention
    BEGIN
         SELECT DISTINCT
            S.SubscriberID,
            S.RepID,
            /*SRepName = 
                CASE 
                    WHEN R.HumanID IS NULL THEN ''
                    ELSE R.LastName + ', ' + R.FirstName
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            SRepName = CASE WHEN R_Rep.BusinessEnd IS NULL THEN 
                    CASE WHEN R.HumanID IS NULL THEN '' ELSE R.LastName + ', ' + R.FirstName + ' (' + R_Rep.Repcode + ')' END
                   ELSE CASE WHEN R.HumanID IS NULL THEN '' ELSE R.LastName + ', ' + R.FirstName + ' (' + R_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            S.ScholarshipLevelID,
            S.AnnualIncome,
            S.StateID,
            S.SemiAnnualStatement,
            SFirstName = SH.FirstName,
            SOrigName = SH.OrigName,
            SLastName = SH.LastName,
            SvcNIP = ISNULL(SH.vcNIP, ''),
            SCompanyName = SH.CompanyName,
            SSexID = SH.SexID,
            SAdrID = SH.AdrID,
            SBirthDate = SH.BirthDate,
            SDeathDate = SH.DeathDate,
            SLangID = SH.LangID,
            SCivilID = SH.CivilID,
            SCourtesyTitle = SH.CourtesyTitle,
            SUsingSocialNumber = SH.UsingSocialNumber,
            SSharePersonalInfo = SH.SharePersonalInfo,
            SMarketingMaterial = SH.MarketingMaterial,
            SIsCompany = SH.IsCompany,
            SSocialNumber = SH.SocialNumber,
            SDriverLicenseNo = SH.DriverLicenseNo,
            SWebSite = SH.WebSite,
            SResidID = SH.ResidID,
            SInForce = SA.InForce,
            SAdrTypeID = SA.AdrTypeID,
            SSourceID = SA.SourceID,
            SAddress = SA.Address,
            SCity = SA.City,
            SStateName = SA.StateName,
            SCountryID = SA.CountryID,
            SZipCode = SA.ZipCode,
            SPhone1 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone1, SA.CountryID),
            SPhone2 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone2, SA.CountryID),
            SFax = dbo.FN_CRQ_FormatPhoneNo(SA.Fax, SA.CountryID),
            SMobile = dbo.FN_CRQ_FormatPhoneNo(SA.Mobile, SA.CountryID),
            SWattLine = dbo.FN_CRQ_FormatPhoneNo(SA.WattLine, SA.CountryID),
            SOtherTel = dbo.FN_CRQ_FormatPhoneNo(SA.OtherTel, SA.CountryID),
            SPager = dbo.FN_CRQ_FormatPhoneNo(SA.Pager, SA.CountryID),
            SEMail = SA.EMail,
            tiSubsCESPState = S.tiCESPState, -- État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)
            Spouse = ISNULL(S.Spouse,''),
            Contact1 = ISNULL(S.Contact1,''),
            Contact2 = ISNULL(S.Contact2,''),
            Contact1Phone = ISNULL(S.Contact1Phone,''),
            Contact2Phone = ISNULL(S.Contact2Phone,''),
            SNEQ = ISNULL(SH.StateCompanyNo,''),
            bSouscripteur_Desire_Releve_Elect = ISNULL(S.bReleve_Papier,0), 
            bSouscripteur_Accepte_Publipostage = SH.bHumain_Accepte_Publipostage,
            B.BeneficiaryID,
            B.GovernmentGrantForm,
            B.BirthCertificate,
            B.PersonalInfo,
            B.ProgramID,
            B.ProgramLength,
            B.ProgramYear,
            B.SchoolReport,
            B.RegistrationProof,
            B.StudyStart,
            B.CaseOfJanuary,
            B.EligibilityQty,
            B.CollegeID,
            bBeneficiaryAddressLost = B.bAddressLost,
            tiPCGType =
                CASE 
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 0 THEN 0
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 1 THEN 1
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 1 THEN 2
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 0 THEN 3
                END, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise-Souscripteur, 3=Entreprise)
            B.vcPCGFirstName, -- Prénom du principal responsable s’il s’agit d’un souscripteur ou d’une personne. Nom de l’entreprise principal responsable dans l’autre cas.
            B.vcPCGLastName, -- Nom du principal responsable s’il s’agit d’un souscripteur ou d’une personne.
            B.vcPCGSINOrEN, -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
            bBeneficiaire_Accepte_Publipostage = BH.bHumain_Accepte_Publipostage,
            tiBenefCESPState = B.tiCESPState,
            Co.CollegeTypeID,
            B.EligibilityConditionID,
            Co.CollegeCode,
            CollegeName = CoCo.CompanyName,
            Prog.ProgramDesc,
            BFirstName = BH.FirstName,
            BOrigName = BH.OrigName,
            BInitial = BH.Initial,
            BLastName = BH.LastName,
            BvcNIP = ISNULL(BH.vcNIP, ''),
            BCompanyName = BH.CompanyName,
            BSexID = BH.SexID,
            BAdrID = BH.AdrID,
            BBirthDate = BH.BirthDate,
            BDeathDate = BH.DeathDate,
            BLangID = BH.LangID,
            BCivilID = BH.CivilID,
            BCourtesyTitle = BH.CourtesyTitle,
            BUsingSocialNumber = BH.UsingSocialNumber,
            BSharePersonalInfo = BH.SharePersonalInfo,
            BMarketingMaterial = BH.MarketingMaterial,
            BIsCompany = BH.IsCompany,
            BSocialNumber = BH.SocialNumber,
            BDriverLicenseNo = BH.DriverLicenseNo,
            BWebSite = BH.WebSite,
            BResidID = BH.ResidID,
            BNEQ = ISNULL(BH.StateCompanyNo,''),
            BInForce = BA.InForce,
            BAdrTypeID = BA.AdrTypeID,
            BSourceID = BA.SourceID,
            BAddress = BA.Address,
            BCity = BA.City,
            BStateName = BA.StateName,
            BCountryID = BA.CountryID,
            BZipCode = BA.ZipCode,
            BPhone1 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone1, BA.CountryID),
            BPhone2 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone2, BA.CountryID),
            BFax = dbo.FN_CRQ_FormatPhoneNo(BA.Fax, BA.CountryID),
            BMobile = dbo.FN_CRQ_FormatPhoneNo(BA.Mobile, BA.CountryID),
            BWattLine = dbo.FN_CRQ_FormatPhoneNo(BA.WattLine, BA.CountryID),
            BOtherTel = dbo.FN_CRQ_FormatPhoneNo(BA.OtherTel, BA.CountryID),
            BPager = dbo.FN_CRQ_FormatPhoneNo(BA.Pager, BA.CountryID),
            BEMail = BA.EMail,
            C.ConventionID,
            C.ConventionNo,
            C.YearQualif,
            C.tiMaximisationREEE,
            PmtDate = C.FirstPmtDate,
            C.PmtTypeID,
            C.tiRelationshipTypeID,
            RT.vcRelationshipType,
            C.GovernmentRegDate,
            C.ScholarshipYear,
            C.ScholarshipEntryID,
            C.dtRegEndDateAdjust,
            dtConvInforceDateTIN = C.dtInforceDateTIN,
            C.CoSubscriberID,
            CPlanID = PC.PlanID,
            CPlanTypeID = PC.PlanTypeID,
            CPlanDesc = PC.PlanDesc,
            C.bTuteur_Desire_Releve_Elect,
            U.UnitID,
            U.UnitQty,
            U.InForceDate,
            U.SignatureDate,
            U.TerminatedDate,
            U.IntReimbDate,
            U.ActivationConnectID,
            U.ValidationConnectID,
            U.BenefInsurID,
            U.WantSubscriberInsurance,
            URepID = U.RepID,
            /*URepName = 
                CASE ISNULL(U.RepID,0) 
                    WHEN 0 THEN '' 
                ELSE UR.LastName + ', ' + UR.FirstName 
                END, 
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepName = CASE WHEN UR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            URepResponsableID = U.RepResponsableID,
            U.PmtEndConnectID,
            U.IntReimbDateAdjust,
            /*URepResponsableName = 
                CASE ISNULL(U.RepResponsableID,0) 
                    WHEN 0 THEN '' 
                ELSE URR.LastName + ', ' + URR.FirstName 
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepResponsableName = CASE WHEN URR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            U.StopRepComConnectID,
            U.SubscribeAmountAjustment,
            U.LastDepositForDoc,
            U.dtCotisationEndDateAdjust,
            U.dtInforceDateTIN,
            U.iSous_Cat_ID,
            MCD.YearQty,
            M.ModalID,
            M.ModalDate,
            M.PmtByYearID,
            M.PmtQty,
            M.PmtRate,
            M.SubscriberInsuranceRate,
            M.BenefAgeOnBegining,
            FeeByUnit = CASE WHEN FBU.iID_Convention_Destination IS NULL THEN  M.FeeByUnit ELSE 0 END,
            M.FeeSplitByUnit,
            M.FeeRefundable,
            P.tiAgeQualif,
            M.BusinessBonusToPay,
            BI.BenefInsurDate,
            BI.BenefInsurFaceValue,
            BI.BenefInsurPmtByYear,
            BI.BenefInsurRate,
            P.PlanID,
            P.PlanDesc,
            P.PlanTypeID,
            P.IntReimbAge,
            CA.BankID,
            CA.AccountName,
            CA.TransitNo,
            BK.BankTransit,
            BK.BankName,
            BK.BankTypeName,
            BK.BankTypeCode,
            ConventionBreaking = ISNULL(Bkg.ConventionID,0),
            UnitHoldPayment = ISNULL(uhp.UnitID,0),
            StateTaxPct = ISNULL(St.StateTaxPct,0),
            FirstPmtDate = Ct.OperDate,
            Cotisation = ISNULL(Ct.Cotisation, 0),
            Fee = ISNULL(Ct.Fee, 0),
            CapitalInterestAmount = ISNULL(CI.CapitalInterestAmount, 0),
            GrantInterestAmount = ISNULL(CG.GrantInterestAmount, 0),
            AvailableFeeAmount = ISNULL(CF.AvailableFeeAmount, 0),
            AutomaticDepositCount = ISNULL(AD.AutomaticDepositCount, 0),
            CoSubscriberName = 
                CASE 
                    WHEN ISNULL(C.CoSubscriberID, 0) = 0 THEN '' 
                    WHEN SHC.IsCompany = 1 THEN SHC.LastName
                ELSE SHC.LastName + ', ' + SHC.FirstName 
                END,
            NbNSF = ISNULL(NSF.NbNSF,0),
            SS.SaleSourceID, --point 718
            SS.SaleSourceDesc, --point 718
            bIsContestWinner = ISNULL(SS.bIsContestWinner,0),
            TotalCapitalInsured = 
                CASE 
                    WHEN ISNULL(TC.TotalCapitalInsured,0) > 0 THEN TC.TotalCapitalInsured 
                ELSE 0 
                END, -- point#729
            CESGInForceDate = GGI.InForceDate, -- #0768-05
            CS.ConventionStateID,
            CS.ConventionStateName,
            US.UnitStateID,
            US.UnitStateName,
            AutoMonthTheoricAmount = 
                CASE ISNULL(C.PmtTypeID, '') 
                    WHEN 'AUT' THEN ISNULL(AMT.MonthTheoricAmount,0) 
                END, -- Valeur retournée seulement si paiement automatique
            BirthLangID = ISNULL(WorldLanguageCodeID,''),
            BirthLangName = ISNULL(WorldLanguage,''),
            S.AddressLost,
            UDirName = 
                CASE ISNULL(UDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HUDIR.LastName + ', ' + HUDIR.FirstName 
                END,
            SDirName = 
                CASE ISNULL(SDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HSDIR.LastName + ', ' + HSDIR.FirstName 
                END,
            C.bSendToCESP, -- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
            fCESG = ISNULL(GG.fCESG,0), -- Solde du compte de SCEE de la convention.
            fACESG = ISNULL(GG.fACESG,0), -- Solde du compte de SCEE+ de la convention.
            fCLB = ISNULL(GG.fCLB,0), -- Solde du compte de BEC de la convention.
            C.bCESGRequested, -- SCEE voulue (1) ou non (2)
            C.bACESGRequested, -- SCEE+ voulue (1) ou non (2)
            C.bCLBRequested, -- BEC voulu (1) ou non (2)
            C.tiCESPState, -- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
            DiplomaTextID = 9999, -- DT.DiplomaTextID,  -- ID unique du texte du diplôme        -- 2015-07-29
            DiplomaText = ISNULL(C.TexteDiplome, ''), -- DT.DiplomaText, -- Texte du diplôme        -- 2015-07-29
            B.iTutorID, -- ID du tuteur, correspond au HumanID.
            B.bTutorIsSubscriber, -- Si le Tuteur est un souscripteur ou non
            TvcEN = Tu.vcEN, -- Numéro d’entreprise, si le tuteur en est une.
            TFirstName = TuH.FirstName, -- Prénom du tuteur
            TOrigName = TuH.OrigName, -- Nom à la naissance
            TInitial = TuH.Initial, -- Initial (Jr, Sr, etc.)
            TLastName = TuH.LastName, -- Nom
            TvcNIP = ISNULL(TuH.vcNIP, ''),
            TBirthDate = TuH.BirthDate, -- Date de naissance
            TDeathDate = TuH.DeathDate, -- Date du décès
            TSexID = TuH.SexID, -- Sexe (code)
            TLangID = TuH.LangID, -- Langue (code)
            TCivilID = TuH.CivilID, -- Statut civil (code)
            TSocialNumber = TuH.SocialNumber, -- Numéro d’assurance sociale
            TResidID = TuH.ResidID, -- Pays de résidence (code)
            TDriverLicenseNo = TuH.DriverLicenseNo, -- Numéro de permis
            TWebSite = TuH.WebSite, -- Site internet
            TCourtesyTitle = TuH.CourtesyTitle, -- Titre de courtoisie (Docteur, Professeur, etc.)
            TUsingSocialNumber = TuH.UsingSocialNumber, -- Droit d’utiliser le NAS.
            TSharePersonalInfo = TuH.SharePersonalInfo, -- Droit de partager les informations personnelles
            TMarketingMaterial = TuH.MarketingMaterial, -- Veux recevoir le matériel publicitaire.
            TIsCompany = TuH.IsCompany, -- Compagny ou humain
            TInForce = TuA.InForce, -- Date d’entrée en vigueur de l’adresse.
            TAdrTypeID = TuA.AdrTypeID, -- Type d’adresse (H = humain, C = Compagnie)
            TSourceID = TuA.SourceID, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
            TAddress = TuA.Address, -- # civique, rue et # d’appartement.
            TCity = TuA.City, -- Ville
            TStateName = TuA.StateName, -- Province
            TCountryID = TuA.CountryID, -- Pays (code)
            TZipCode = TuA.ZipCode, -- Code postal
            TPhone1 = TuA.Phone1, -- Tél. résidence
            TPhone2 = TuA.Phone2, -- Tél. bureau
            TFax = TuA.Fax, -- Fax
            TMobile = TuA.Mobile, -- Tél. cellulaire
            TWattLine = TuA.WattLine, -- Tél. sans frais
            TOtherTel = TuA.OtherTel, -- Autre téléphone.
            TPager = TuA.Pager, -- Paget
            TEmail = TuA.Email, -- Courriel
            fAvailableUnitQty = ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0),
            ConventionIDInd=C2.ConventionID, --Id convention individuelle RIO
            ConventionNoInd=C2.ConventionNo, --No convnetion individuelle RIO                    
            PaysOrigine = ISNULL(Corg.CountryName, ''), --Pays d'origine            
            PreferenceSuiviID = ISNULL(S.iID_Preference_Suivi, 0), --Preference suivi
            NoPersonnesaCharge=ISNULL(PS.tiNB_Personnes_A_Charge,0), --Ajout de la table tblCONV_ProfilSouscripteur
            ConnaisancePlacementID=ISNULL(PS.iID_Connaissance_Placements,0),
            RevenuFamilialID=ISNULL(PS.iID_Revenu_Familial,0),
            DepassementBaremeID=ISNULL(PS.iID_Depassement_Bareme,0),
            IdentiteSouscripteurID=ISNULL(S.iID_Identite_Souscripteur,0),
            ObjectifInvestissementLigne1ID=ISNULL(PS.iID_ObjectifInvestissementLigne1,0),
            ObjectifInvestissementLigne2ID=ISNULL(PS.iID_ObjectifInvestissementLigne2,0),
            ObjectifInvestissementLigne3ID=ISNULL(PS.iID_ObjectifInvestissementLigne3,0),
            IdentiteDescription=ISNULL(S.vcIdentiteVerifieeDescription,''),
            AutorisationResiliation=ISNULL(S.bAutorisation_Resiliation,0),
            DepassementJustification=ISNULL(PS.vcDepassementbaremeJustification,''),
            EstimationCoutEtudesID = ISNULL(PS.iID_Estimation_Cout_Etudes, 0),
            EstimationValeurNetteMenageID = ISNULL(PS.iID_Estimation_Valeur_Nette_Menage, 0), 
            DestinationRemboursementID=ISNULL(C.iID_Destinataire_Remboursement, 0), --L'ID du Destination remboursement
            DestinationRemboursementAutre=ISNULL(C.vcDestinataire_Remboursement_Autre, ''), --Destination remboursement autre
            DateduProspectus=ISNULL(C.dtDateProspectus, ''), --Date du prospectus
            SouscripteurDesireIQEE=ISNULL(C.bSouscripteur_Desire_IQEE, 0), --Souscripteur desire IQEE
            C.tiID_Lien_CoSouscripteur,
            LienCoSouscripteur=ISNULL(LC.vcRelationshipType,''),
            C.iSous_Cat_ID_Resp_Prelevement,
            IDNiveauEtudeMere        = ISNULL(PS.iIDNiveauEtudeMere,    0),            -- 2010-01-06 : JFG :Modification des champs du profil souscripteur
            IDNiveauEtudePere        = ISNULL(PS.iIDNiveauEtudePere, 0),
            IDNiveauEtudeTuteur        = ISNULL(PS.iIDNiveauEtudeTuteur, 0),
            IDImportanceEtude        = ISNULL(PS.iIDImportanceEtude, 0),
            IDEpargneEtudeEnCours    = ISNULL(PS.iIDEpargneEtudeEnCours, 0),
            IDContributionFinanciereParent = ISNULL(PS.iIDContributionFinanciereParent,    0),
            IDConditionEligibleBenef = ISNULL(B.EligibilityConditionID, ''),
            URR_Rep.iNumeroBDNI,
            C.bFormulaireRecu,
            C.dtRegStartDate,
            C.bSouscripteur_Desire_IQEE,
            IQEE        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            IQEEMaj        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            ConventionTypeInd            = S1.OperTypeID,                -- Type de la convention individuelle (RIO, RIM ou TRI)    
            vcOccupation                    = ISNULL(SH.vcOccupation, ''),                        -- Occupation de l'humain    
            vcEmployeur                        = ISNULL(SH.vcEmployeur, ''),                        -- Employeur de l'humain    
            tiNbAnneesService                = ISNULL(SH.tiNbAnneesService, ''),                    -- Nombre d'années de service    
            bRapport_Annuel_Direction        = ISNULL(S.bRapport_Annuel_Direction, 0),            -- Désire le rapport annuel de la direction
            bEtats_Financiers_Annuels        = ISNULL(S.bEtats_Financiers_Annuels, 0),            -- Désire les états financiers annuels    
            vcJustifObjectifsInvestissement    = ISNULL(PS.vcJustifObjectifsInvestissement, ''),    -- Justification du choix des objectifs d'investissement
            bEtats_Financiers_Semestriels    = ISNULL(S.bEtats_Financiers_Semestriels, 0),        -- Désire les états financiers semestriels    
            C.vcCommInstrSpec,
            iIDJustificationConvIncomplete = ISNULL(C.iID_Justification_Conv_Incomplete, 0),
--            bAImprimer                       = ISNULL(C.bAImprimer, 0),
            bStatutPortailSubscriber       = CASE when PAS.iUserId is NULL THEN 0 ELSE 1 END,
            bStatutPortailBeneficiary       = CASE when PAB.iUserId is NULL THEN 0 ELSE 1 END,
            DateRQ = dbo.fnIQEE_ObtenirDateEnregistrementRQ(C.ConventionID), 
              DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL), 
            DateFinRegimeOriginale = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'T', NULL),
            DateEntreeVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
            ,bConsentement_Souscripteur = CASE WHEN ISNULL(PAS.iEtat, 0) = 5 THEN CAST('1' AS bit) ELSE cast('0' AS bit) END 
            ,bConsentement_Beneficiaire = ISNULL(B.bReleve_Papier,0)  
            ,vcDossierBeneficiaire = GPB.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(BH.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(BH.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(BH.firstname)),' ','_') + '_' + cast(BH.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,vcDossierSouscripteur = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(sh.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(sh.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(sh.firstname)),' ','_') + '_' + cast(sh.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,ToleranceRisqueID=ISNULL(PS.iID_Tolerance_Risque,0)
        FROM dbo.Un_Convention C
        JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID
        LEFT JOIN (-- Date de vigueur enregistrée à la SCÉÉ #0768-07
            SELECT 
                G.ConventionID,
                InForceDate = MIN(G.dtTransaction)
            FROM Un_CESP100 G
            LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
            JOIN (-- Retourne la plus grande date de fichier scee envoyé par convention
                SELECT 
                    G.ConventionID,
                    dtCESPSendFile = MAX(ISNULL(S.dtCESPSendFile, @Today))
                FROM Un_CESP100 G
                LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
                WHERE G.ConventionID = @MatrixID
                GROUP BY G.ConventionID
                ) V ON V.ConventionID = G.ConventionID AND ISNULL(S.dtCESPSendFile, @Today) = V.dtCESPSendFile
            GROUP BY G.ConventionID
            ) GGI ON GGI.ConventionID = C.ConventionID
        LEFT JOIN dbo.Mo_Human SHC ON SHC.HumanID = C.CoSubscriberID
        LEFT JOIN (-- Retourne la somme des intérêts sur montant souscrit par convention
            SELECT
                ConventionID,
                CapitalInterestAmount = SUM(ConventionOperAmount) 
            FROM Un_ConventionOper
            WHERE ConventionID = @MatrixID
              AND ConventionOperTypeID = 'INM'
            GROUP BY ConventionID
            ) CI ON CI.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des intérêts sur subvention par convention
            SELECT
                ConventionID,
                GrantInterestAmount = SUM(ConventionOperAmount)
            FROM Un_ConventionOper
            WHERE ConventionID = @MatrixID
              AND CHARINDEX(','+ConventionOperTypeID+',',@vcCONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION) > 0
            GROUP BY ConventionID
            ) CG ON CG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des frais disponibles par convention
            SELECT
                ConventionID,
                AvailableFeeAmount = SUM(ConventionOperAmount)
            FROM Un_ConventionOper
            WHERE ConventionID = @MatrixID
              AND ConventionOperTypeID = 'FDI'
            GROUP BY ConventionID
            ) CF ON CF.ConventionID = C.ConventionID
        LEFT JOIN Un_Plan PC ON PC.PlanID = C.PlanID
        JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
        JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
        LEFT JOIN dbo.Mo_Adr BA ON BA.AdrID = BH.AdrID
        LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
        LEFT JOIN Un_Modal M ON M.ModalID = U.ModalID
        LEFT JOIN Un_Plan P ON P.PlanID = M.PlanID
        JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
        JOIN dbo.Mo_Human SH ON SH.HumanID = S.SubscriberID
        LEFT JOIN dbo.Mo_Adr SA ON SA.AdrID = SH.AdrID
        --LEFT JOIN dbo.Mo_Human R ON R.HumanID = S.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep R_Rep ON R_Rep.RepID = S.RepID
        LEFT JOIN dbo.Mo_Human R ON R.HumanID = R_Rep.RepID
        --LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = U.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep UR_Rep ON UR_Rep.RepID = U.RepID
        LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = UR_Rep.RepID
        --LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = U.RepResponsableID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep URR_Rep ON URR_Rep.RepID = U.RepResponsableID
        LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = URR_Rep.RepID
        LEFT JOIN (-- point#729 
            SELECT 
                V1.SubscriberID, 
                TotalCapitalInsured = SubscribAmount - ISNULL(AmountToDate,0) 
            FROM (-- Retourne le total des montants versés par souscripteur
                SELECT 
                    C.SubscriberID, 
                    SubscribAmount = SUM(ROUND(M.PmtRate*U.UnitQty,2) * PmtQty)
                FROM dbo.Un_Convention C 
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                WHERE C.ConventionID = @MatrixID
                  AND U.WantSubscriberInsurance <> 0
                  AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID 
                ) V1 
            LEFT JOIN (-- Retourne les cotisations versées jusqu'à présent par souscripteurs
                SELECT 
                    C.SubscriberID, 
                    AmountToDate = SUM(Co.Cotisation + Co.Fee)
                FROM dbo.Un_Convention C 
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                WHERE C.ConventionID = @MatrixID
                  AND U.WantSubscriberInsurance <> 0
                  AND M.SubscriberInsuranceRate > 0 
                GROUP BY C.SubscriberID 
                ) V2 ON V1.SubscriberID = V2.SubscriberID
            ) TC     ON TC.SubscriberID = S.SubscriberID
        LEFT JOIN (-- Retourne le total des cotisations et de frais ainsi que la plus petite date d'opération par unités
            SELECT
                Ct.UnitID,
                OperDate = MIN(O.OperDate),
                FEE = SUM(Ct.Fee) ,
                Cotisation = SUM(Ct.Cotisation)
            FROM Un_Cotisation Ct
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN Un_Oper O ON O.OperID = Ct.OperID
            LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
            WHERE U.ConventionID = @MatrixID
                AND(    ( O.OperTypeID = 'CPA' 
                         AND ISNULL(OBF.OperID, 0) > 0
                        )
                    OR O.OperDate < = GETDATE()
                    )
            GROUP BY Ct.UnitID
            ) Ct ON Ct.UnitID = U.UnitID
        LEFT JOIN ( -- Sert à la détection d'un arrêt de paiement sur le groupe d'unité
            SELECT DISTINCT 
                H.UnitID
            FROM Un_UnitHoldPayment H
            JOIN dbo.Un_Unit U ON U.UnitID = H.UnitID
            WHERE U.ConventionID = @MatrixID
                AND H.StartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(H.EndDate,0) <= 0
                        OR H.EndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) UHP ON UHP.UnitID = U.UnitID
        LEFT JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne l'info des banques
            SELECT
                B.BankID,
                B.BankTransit,
                BankName = C.CompanyName,
                BT.BankTypeName,
                BT.BankTypeCode
            FROM Mo_Bank B
            JOIN Mo_Company C ON C.CompanyID = B.BankID
            JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
            JOIN Un_ConventionAccount CA ON CA.BankID = B.BankID
            WHERE CA.ConventionID = @MatrixID
            ) BK ON BK.BankID = CA.BankID
        LEFT JOIN Un_Program Prog ON Prog.ProgramID = B.ProgramID
        LEFT JOIN Un_College Co ON Co.CollegeID = B.CollegeID
        LEFT JOIN Mo_Company CoCo ON CoCo.CompanyID = Co.CollegeID
        LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
        LEFT JOIN Mo_State St ON St.StateID = S.StateID
        LEFT JOIN (-- Retourne les conventions en arrêt de paiement            
            SELECT DISTINCT 
                ConventionID
            FROM Un_Breaking
            WHERE ConventionID = @MatrixID
                AND BreakingStartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(BreakingEndDate,0) <= 0
                        OR BreakingEndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) BKG ON BKG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne le nombre de dépôts par unité
            SELECT
                A.UnitID,
                AutomaticDepositCount = COUNT(A.AutomaticDepositID)
            FROM Un_AutomaticDeposit A
            JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
            WHERE U.ConventionID = @MatrixID
                AND    ( dbo.FN_CRQ_DateNoTime(GETDATE()) BETWEEN A.StartDate AND A.EndDate
                         OR    ( dbo.FN_CRQ_DateNoTime(GETDATE()) >= A.StartDate 
                                AND ISNULL(A.EndDate,0) < 2
                                )
                        )
            GROUP BY A.UnitID
            ) AD ON AD.UnitID = U.UnitID
        LEFT JOIN (-- Retourne le nombre de nsf par convention    
            SELECT
                U.ConventionID,
                NbNSF = COUNT(DISTINCT O.OperID) 
            FROM Mo_BankReturnLink R
            JOIN Un_Oper O ON O.OperID = R.BankReturnCodeID
            JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            WHERE U.ConventionID = @MatrixID
              AND R.BankReturnTypeID = '901'
            GROUP BY U.ConventionID    
            ) NSF ON NSF.ConventionID = C.ConventionID
        LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
        LEFT JOIN (-- 10.23.1 (2.2) : Retrouve l'état actuel d'une convention
            SELECT 
                T.ConventionID,
                CS.ConventionStateID,
                CS.ConventionStateName
            FROM (-- Retourne la plus grande date de début d'un état par convention
                SELECT 
                    ConventionID,
                    MaxDate = MAX(StartDate)
                FROM Un_ConventionConventionState
                WHERE ConventionID = @MatrixID
                  AND StartDate <= GETDATE()
                GROUP BY ConventionID
                ) T
            JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID    AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
            JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
            ) CS ON C.ConventionID = CS.ConventionID
        LEFT JOIN (-- 10.23.1 (3.2) : Retrouve l'état actuel d'un groupe d'unités
            SELECT 
                T.UnitID,
                US.UnitStateID,
                US.UnitStateName
            FROM (-- Retourne la plus grande date de début d'un état par unité
                SELECT 
                    S.UnitID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_UnitUnitState S
                JOIN dbo.Un_Unit U ON U.UnitID = S.UnitID
                WHERE U.ConventionID = @MatrixID
                  AND S.StartDate <= GETDATE()
                GROUP BY S.UnitID
                ) T
            JOIN Un_UnitUnitState UUS ON T.UnitID = UUS.UnitID AND T.MaxDate = UUS.StartDate -- Retrouve l'état correspondant à la plus grande date par unité
            JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID -- Pour retrouver la description de l'état
            ) US ON U.UnitID = US.UnitID
        LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
            SELECT
                U.ConventionID,
                MonthTheoricAmount = 
                    SUM(
                        ROUND(M.PmtRate * U.UnitQty,2) + -- Cotisation et frais
                        dbo.FN_CRQ_TaxRounding
                            ((    CASE U.WantSubscriberInsurance -- Assurance souscripteur
                                    WHEN 0 THEN 0
                                ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
                                END +
                                ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
                            (1+ISNULL(St.StateTaxPct,0)))) -- Taxes
            FROM dbo.Un_Unit U
            JOIN Un_Modal M ON U.ModalID = M.ModalID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            LEFT JOIN Mo_State St ON St.StateID = S.StateID
            LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
            LEFT JOIN (
                SELECT
                    U.UnitID,
                    CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
                FROM dbo.Un_Unit U
                JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
                WHERE U.ConventionID = @MatrixID
                GROUP BY U.UnitID
                ) Ct ON U.UnitID = Ct.UnitID
            WHERE U.ConventionID = @MatrixID
              AND M.PmtByYearID = 12
              AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
            GROUP BY U.ConventionID
            ) AMT ON C.ConventionID = AMT.ConventionID 
        LEFT JOIN CRQ_WorldLang W ON S.BirthLangID = W.WorldLanguageCodeID
        LEFT JOIN (
            SELECT
                M.UnitID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    U.UnitID,
                    U.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Unit U
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
                JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
                JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
                WHERE C.ConventionID = @MatrixID
                GROUP BY U.UnitID, U.RepID
                ) M
            JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
            WHERE C.ConventionID = @MatrixID
            GROUP BY M.UnitID
            ) UDIR ON UDIR.UnitID = U.UnitID
        LEFT JOIN dbo.Mo_Human HUDIR ON HUDIR.HumanID = UDIR.BossID
        LEFT JOIN (
            SELECT
                M.SubscriberID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    S.SubscriberID,
                    S.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Subscriber S
                JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID
                JOIN Un_RepBossHist RBH ON RBH.RepID = S.RepID AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
                JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
                JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)
                WHERE C.ConventionID = @MatrixID
                GROUP BY S.SubscriberID, S.RepID
                ) M
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = M.SubscriberID
            JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID
            JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
            WHERE C.ConventionID = @MatrixID
            GROUP BY M.SubscriberID
            ) SDIR ON SDIR.SubscriberID = S.SubscriberID
        LEFT JOIN dbo.Mo_Human HSDIR ON HSDIR.HumanID = SDIR.BossID
        LEFT JOIN (
            SELECT 
                ConventionID,
                fCESG = SUM(fCESG),
                fACESG = SUM(fACESG),
                fCLB = SUM(fCLB)
            FROM Un_CESP
            WHERE ConventionID = @MatrixID
            GROUP BY ConventionID
            ) GG ON GG.ConventionID = C.ConventionID
        --LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID
        LEFT JOIN Un_Tutor Tu ON Tu.iTutorID = B.iTutorID AND B.bTutorIsSubscriber = 0
        LEFT JOIN dbo.Mo_Human TuH ON TuH.HumanID = B.iTutorID
        LEFT JOIN dbo.Mo_Adr TuA ON TuA.AdrID = TuH.AdrID
        LEFT JOIN ( -- Unité résiliés
                SELECT 
                    U.ConventionID, 
                    UnitRes = SUM(UR.UnitQty)
                FROM Un_UnitReduction UR
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                WHERE U.ConventionID = @MatrixID
                GROUP BY U.ConventionID) SR ON SR.ConventionID = C.ConventionID
        LEFT JOIN ( -- Unité utilisés
                SELECT 
                    U.ConventionID, 
                    UnitUse = SUM(A.fUnitQtyUse)
                FROM Un_UnitReduction UR
                JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID        
                WHERE U.ConventionID = @MatrixID
                GROUP BY U.ConventionID) SU ON SU.ConventionID = C.ConventionID
        LEFT JOIN @tUn_MaxConvDepositDateCfg MCD ON U.InForceDate BETWEEN MCD.dtStart AND MCD.dtEnd

        LEFT JOIN (SELECT iID_Convention_Source,iID_Convention_Destination = min(iID_Convention_Destination), iID_Unite_Source, TOPER.OperTypeID
                    FROM tblOPER_OperationsRIO TOPER 
                    WHERE (TOPER.bRIO_ANNULEE = 0 AND TOPER.bRIO_QUIANNULE = 0)
                    GROUP BY iID_Convention_Source, iID_Unite_Source, TOPER.OperTypeID) AS S1 ON S1.iID_Convention_Source = C.ConventionID  AND S1.iID_Unite_Source = U.UnitID

        LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = S1.iID_Convention_Destination
        LEFT JOIN Mo_Country Corg ON Corg.CountryID = SH.cID_Pays_Origine --Pays d'origine
        LEFT JOIN Un_RelationshipType LC ON LC.tiRelationshipTypeID = C.tiID_Lien_CoSouscripteur
        LEFT JOIN tblCONV_PreferenceSuivi Prf ON PRF.iID_Preference_Suivi = S.iID_Preference_Suivi --Preference suivi
        LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID AND PS.DateProfilInvestisseur = (
            SELECT    
                MAX(PSM.DateProfilInvestisseur)
            FROM tblCONV_ProfilSouscripteur PSM
            WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
                AND PSM.DateProfilInvestisseur <= GETDATE()
            )
        LEFT JOIN tblGENE_PortailAuthentification PAS ON PAS.iUserId = S.SubscriberID 
        LEFT JOIN tblGENE_PortailAuthentification PAB ON PAB.iUserId = B.BeneficiaryID
        LEFT JOIN tblGENE_TypesParametre GTPB on GTPB.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE'
        LEFT JOIN tblGENE_Parametres GPB ON GTPB.iID_Type_Parametre = GPB.iID_Type_Parametre
        LEFT JOIN tblGENE_TypesParametre GTPS on GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR'
        LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
        LEFT JOIN (
            SELECT r.iID_Convention_Destination
            from tblOPER_OperationsRIO r
            WHERE r.OperTypeID IN ('RIO', 'RIM')
            AND r.bRIO_QuiAnnule = 0
            GROUP BY r.iID_Convention_Destination
                )FBU ON C.ConventionID = FBU.iID_Convention_Destination
        WHERE C.ConventionID = @MatrixID

        ORDER BY
            SH.LastName,
            SH.FirstName,
            C.ConventionNo,
            BH.LastName,
            BH.FirstName
    END -- ELSE IF (@MatrixType = 'CON') 
    ELSE IF @MatrixType = 'REP' -- Représentant
    BEGIN
       SELECT
            S.SubscriberID,
            R.RepID,
            R.RepCode,
            R.RepLicenseNo,
            R.BusinessStart,
            R.BusinessEnd,
            HistVerifConnectID = ISNULL(R.HistVerifConnectID, 0),
            RFirstName = RH.FirstName,
            ROrigName = RH.OrigName,
            /*SRepName = 
                CASE 
                    WHEN RH.HumanID IS NULL THEN ''
                    ELSE RH.LastName + ', ' + RH.FirstName
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            SRepName = CASE WHEN RH_Rep.BusinessEnd IS NULL THEN 
                    CASE WHEN RH.HumanID IS NULL THEN '' ELSE RH.LastName + ', ' + RH.FirstName + ' (' + RH_Rep.Repcode + ')' END
                   ELSE CASE WHEN RH.HumanID IS NULL THEN '' ELSE RH.LastName + ', ' + RH.FirstName + ' (' + RH_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            RInitial = RH.Initial,
            RLastName = RH.LastName,
            RvcNIP = ISNULL(RH.vcNIP, ''),
            RCompanyName = RH.CompanyName,
            RSexID = RH.SexID,
            RAdrID = RH.AdrID,
            RBirthDate = RH.BirthDate,
            RDeathDate = RH.DeathDate,
            RLangID = RH.LangID,
            RCivilID = RH.CivilID,
            RCourtesyTitle = RH.CourtesyTitle,
            RUsingSocialNumber = RH.UsingSocialNumber,
            RSharePersonalInfo = RH.SharePersonalInfo,
            RMarketingMaterial = RH.MarketingMaterial,
            RIsCompany = RH.IsCompany,
            RSocialNumber = RH.SocialNumber,
            RDriverLicenseNo = RH.DriverLicenseNo,
            RWebSite = RH.WebSite,
            RResidID = RH.ResidID,
            RInForce = RA.InForce,
            RAdrTypeID = RA.AdrTypeID,
            RSourceID = RA.SourceID,
            RAddress = RA.Address,
            RCity = RA.City,
            RStateName = RA.StateName,
            RCountryID = RA.CountryID,
            RZipCode = RA.ZipCode,
            RPhone1 = dbo.FN_CRQ_FormatPhoneNo(RA.Phone1, RA.CountryID),
            RPhone2 = dbo.FN_CRQ_FormatPhoneNo(RA.Phone2, RA.CountryID),
            RFax = dbo.FN_CRQ_FormatPhoneNo(RA.Fax, RA.CountryID),
            RMobile = dbo.FN_CRQ_FormatPhoneNo(RA.Mobile, RA.CountryID),
            RWattLine = dbo.FN_CRQ_FormatPhoneNo(RA.WattLine, RA.CountryID),
            ROtherTel = dbo.FN_CRQ_FormatPhoneNo(RA.OtherTel, RA.CountryID),
            RPager = dbo.FN_CRQ_FormatPhoneNo(RA.Pager, RA.CountryID),
            REMail = RA.EMail,
            S.ScholarshipLevelID,
            S.AnnualIncome,
            S.StateID,
            S.SemiAnnualStatement,
            SFirstName = SH.FirstName,
            SOrigName = SH.OrigName,
            SLastName = SH.LastName,
            SvcNIP = ISNULL(SH.vcNIP, ''),
            SCompanyName = SH.CompanyName,
            SSexID = SH.SexID,
            SAdrID = SH.AdrID,
            SBirthDate = SH.BirthDate,
            SDeathDate = SH.DeathDate,
            SLangID = SH.LangID,
            SCivilID = SH.CivilID,
            SCourtesyTitle = SH.CourtesyTitle,
            SUsingSocialNumber = SH.UsingSocialNumber,
            SSharePersonalInfo = SH.SharePersonalInfo,
            SMarketingMaterial = SH.MarketingMaterial,
            SIsCompany = SH.IsCompany,
            SSocialNumber = SH.SocialNumber,
            SDriverLicenseNo = SH.DriverLicenseNo,
            SWebSite = SH.WebSite,
            SResidID = SH.ResidID,
            SInForce = SA.InForce,
            SAdrTypeID = SA.AdrTypeID,
            SSourceID = SA.SourceID,
            SAddress = SA.Address,
            SCity = SA.City,
            SStateName = SA.StateName,
            SCountryID = SA.CountryID,
            SZipCode = SA.ZipCode,
            SPhone1 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone1, SA.CountryID),
            SPhone2 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone2, SA.CountryID),
            SFax = dbo.FN_CRQ_FormatPhoneNo(SA.Fax, SA.CountryID),
            SMobile = dbo.FN_CRQ_FormatPhoneNo(SA.Mobile, SA.CountryID),
            SWattLine = dbo.FN_CRQ_FormatPhoneNo(SA.WattLine, SA.CountryID),
            SOtherTel = dbo.FN_CRQ_FormatPhoneNo(SA.OtherTel, SA.CountryID),
            SPager = dbo.FN_CRQ_FormatPhoneNo(SA.Pager, SA.CountryID),
            SEMail = SA.EMail,
            tiSubsCESPState = S.tiCESPState, -- État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)
            Spouse = ISNULL(S.Spouse,''),
            Contact1 = ISNULL(S.Contact1,''),
            Contact2 = ISNULL(S.Contact2,''),
            Contact1Phone = ISNULL(S.Contact1Phone,''),
            Contact2Phone = ISNULL(S.Contact2Phone,''),
            SNEQ = ISNULL(SH.StateCompanyNo,''),
            bSouscripteur_Desire_Releve_Elect = ISNULL(S.bReleve_Papier,0),        
            bSouscripteur_Accepte_Publipostage = SH.bHumain_Accepte_Publipostage,
            B.BeneficiaryID,
            B.GovernmentGrantForm,
            B.BirthCertificate,
            B.PersonalInfo,
            B.ProgramID,
            B.ProgramLength,
            B.ProgramYear,
            B.SchoolReport,
            B.RegistrationProof,
            B.StudyStart,
            B.CaseOfJanuary,
            B.EligibilityQty,
            B.CollegeID,
            bBeneficiaryAddressLost = B.bAddressLost,
            tiPCGType =
                CASE 
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 0 THEN 0
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 1 THEN 1
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 1 THEN 2
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 0 THEN 3
                END, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise-Souscripteur, 3=Entreprise)
            B.vcPCGFirstName, -- Prénom du principal responsable s’il s’agit d’un souscripteur ou d’une personne. Nom de l’entreprise principal responsable dans l’autre cas.
            B.vcPCGLastName, -- Nom du principal responsable s’il s’agit d’un souscripteur ou d’une personne.
            B.vcPCGSINOrEN, -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
            bBeneficiaire_Accepte_Publipostage = BH.bHumain_Accepte_Publipostage,
            tiBenefCESPState = B.tiCESPState,
            Co.CollegeTypeID,
            B.EligibilityConditionID,
            Co.CollegeCode,
            CollegeName = CoCo.CompanyName,
            Prog.ProgramDesc,
            BFirstName = BH.FirstName,
            BOrigName = BH.OrigName,
            BInitial = BH.Initial,
            BLastName = BH.LastName,
            BvcNIP = ISNULL(BH.vcNIP, ''),
            BCompanyName = BH.CompanyName,
            BSexID = BH.SexID,
            BAdrID = BH.AdrID,
            BBirthDate = BH.BirthDate,
            BDeathDate = BH.DeathDate,
            BLangID = BH.LangID,
            BCivilID = BH.CivilID,
            BCourtesyTitle = BH.CourtesyTitle,
            BUsingSocialNumber = BH.UsingSocialNumber,
            BSharePersonalInfo = BH.SharePersonalInfo,
            BMarketingMaterial = BH.MarketingMaterial,
            BIsCompany = BH.IsCompany,
            BSocialNumber = BH.SocialNumber,
            BDriverLicenseNo = BH.DriverLicenseNo,
            BWebSite = BH.WebSite,
            BResidID = BH.ResidID,
            BNEQ = ISNULL(BH.StateCompanyNo,''),
            BInForce = BA.InForce,
            BAdrTypeID = BA.AdrTypeID,
            BSourceID = BA.SourceID,
            BAddress = BA.Address,
            BCity = BA.City,
            BStateName = BA.StateName,
            BCountryID = BA.CountryID,
            BZipCode = BA.ZipCode,
            BPhone1 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone1, BA.CountryID),
            BPhone2 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone2, BA.CountryID),
            BFax = dbo.FN_CRQ_FormatPhoneNo(BA.Fax, BA.CountryID),
            BMobile = dbo.FN_CRQ_FormatPhoneNo(BA.Mobile, BA.CountryID),
            BWattLine = dbo.FN_CRQ_FormatPhoneNo(BA.WattLine, BA.CountryID),
            BOtherTel = dbo.FN_CRQ_FormatPhoneNo(BA.OtherTel, BA.CountryID),
            BPager = dbo.FN_CRQ_FormatPhoneNo(BA.Pager, BA.CountryID),
            BEMail = BA.EMail,
            C.ConventionID,
            C.ConventionNo,
            C.YearQualif,
            C.tiMaximisationREEE,
            PmtDate = C.FirstPmtDate,
            C.PmtTypeID,
            C.tiRelationshipTypeID,
            RT.vcRelationshipType,
            C.GovernmentRegDate,
            C.ScholarshipYear,
            C.ScholarshipEntryID,
            C.dtRegEndDateAdjust,
            dtConvInforceDateTIN = C.dtInforceDateTIN,
            C.CoSubscriberID,
            CPlanID = PC.PlanID,
            CPlanTypeID = PC.PlanTypeID,
            CPlanDesc = PC.PlanDesc,
            C.bTuteur_Desire_Releve_Elect,
            U.UnitID,
            U.UnitQty,
            U.InForceDate,
            U.SignatureDate,
            U.TerminatedDate,
            U.IntReimbDate,
            U.ActivationConnectID,
            U.ValidationConnectID,
            U.BenefInsurID,
            U.WantSubscriberInsurance,
            URepID = U.RepID,
            /*URepName = 
                CASE ISNULL(U.RepID,0) 
                    WHEN 0 THEN '' 
                ELSE UR.LastName + ', ' + UR.FirstName 
                END, 
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepName = CASE WHEN UR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            URepResponsableID = U.RepResponsableID,
            U.PmtEndConnectID,
            U.IntReimbDateAdjust,
            /*URepResponsableName = 
                CASE ISNULL(U.RepResponsableID,0) 
                    WHEN 0 THEN '' 
                ELSE URR.LastName + ', ' + URR.FirstName 
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepResponsableName = CASE WHEN URR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            U.StopRepComConnectID,
            U.SubscribeAmountAjustment,
            U.LastDepositForDoc,
            U.dtCotisationEndDateAdjust,
            U.dtInforceDateTIN,
            U.iSous_Cat_ID,
            MCD.YearQty,
            M.ModalID,
            M.ModalDate,
            M.PmtByYearID,
            M.PmtQty,
            M.PmtRate,
            M.SubscriberInsuranceRate,
            M.BenefAgeOnBegining,
            FeeByUnit = CASE WHEN FBU.iID_Convention_Destination IS NULL THEN  M.FeeByUnit ELSE 0 END,
            M.FeeSplitByUnit,
            M.FeeRefundable,
            P.tiAgeQualif,
            M.BusinessBonusToPay,
            BI.BenefInsurDate,
            BI.BenefInsurFaceValue,
            BI.BenefInsurPmtByYear,
            BI.BenefInsurRate,
            P.PlanID,
            P.PlanDesc,
            P.PlanTypeID,
            P.IntReimbAge,
            CA.BankID,
            CA.AccountName,
            CA.TransitNo,
            BK.BankTransit,
            BK.BankName,
            BK.BankTypeName,
            BK.BankTypeCode,
            ConventionBreaking = ISNULL(Bkg.ConventionID,0),
            UnitHoldPayment = ISNULL(uhp.UnitID,0),
            StateTaxPct = ISNULL(St.StateTaxPct,0),
            FirstPmtDate = Ct.OperDate,
            Cotisation = ISNULL(Ct.Cotisation, 0),
            Fee = ISNULL(Ct.Fee, 0),
            CapitalInterestAmount = ISNULL(CI.CapitalInterestAmount, 0),
            GrantInterestAmount = ISNULL(CG.GrantInterestAmount, 0),
            AvailableFeeAmount = ISNULL(CF.AvailableFeeAmount, 0),
            AutomaticDepositCount = ISNULL(AD.AutomaticDepositCount, 0),
            CoSubscriberName = 
                CASE 
                    WHEN ISNULL(C.CoSubscriberID, 0) = 0 THEN '' 
                    WHEN SHC.IsCompany = 1 THEN SHC.LastName
                ELSE SHC.LastName + ', ' + SHC.FirstName 
                END,
            NbNSF = ISNULL(NSF.NbNSF,0),
            SS.SaleSourceID, -- point 718
            SS.SaleSourceDesc, -- point 718
            bIsContestWinner = ISNULL(SS.bIsContestWinner,0),
            TotalCapitalInsured = 
                CASE 
                    WHEN ISNULL(TC.TotalCapitalInsured,0) > 0 THEN TC.TotalCapitalInsured 
                ELSE 0 
                END, -- point 729
            CESGInForceDate = GGI.InForceDate, -- #0768-05
            CS.ConventionStateID,
            CS.ConventionStateName,
            US.UnitStateID,
            US.UnitStateName,
            AutoMonthTheoricAmount = 
                CASE ISNULL(C.PmtTypeID, '') 
                    WHEN 'AUT' THEN ISNULL(AMT.MonthTheoricAmount,0) 
                END, -- Valeur retournée seulement si paiement automatique
            BirthLangID = ISNULL(WorldLanguageCodeID,''),
            BirthLangName = ISNULL(WorldLanguage,''),
            S.AddressLost,
            UDirName = 
                CASE ISNULL(UDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HUDIR.LastName + ', ' + HUDIR.FirstName 
                END,
            SDirName = 
                CASE ISNULL(RDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HRDIR.LastName + ', ' + HRDIR.FirstName 
                END,
            RDirName = 
                CASE ISNULL(RDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HRDIR.LastName + ', ' + HRDIR.FirstName 
                END,
            C.bSendToCESP, -- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
            fCESG = ISNULL(GG.fCESG,0), -- Solde du compte de SCEE de la convention.
            fACESG = ISNULL(GG.fACESG,0), -- Solde du compte de SCEE+ de la convention.
            fCLB = ISNULL(GG.fCLB,0), -- Solde du compte de BEC de la convention.
            C.bCESGRequested, -- SCEE voulue (1) ou non (2)
            C.bACESGRequested, -- SCEE+ voulue (1) ou non (2)
            C.bCLBRequested, -- BEC voulu (1) ou non (2)
            C.tiCESPState, -- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
            DiplomaTextID = 9999, -- DT.DiplomaTextID,  -- ID unique du texte du diplôme        -- 2015-07-29
            DiplomaText = ISNULL(C.TexteDiplome, ''), -- DT.DiplomaText, -- Texte du diplôme        -- 2015-07-29
            B.iTutorID, -- ID du tuteur, correspond au HumanID.
            B.bTutorIsSubscriber, -- Si le Tuteur est un souscripteur ou non
            TvcEN = Tu.vcEN, -- Numéro d’entreprise, si le tuteur en est une.
            TFirstName = TuH.FirstName, -- Prénom du tuteur
            TOrigName = TuH.OrigName, -- Nom à la naissance
            TInitial = TuH.Initial, -- Initial (Jr, Sr, etc.)
            TLastName = TuH.LastName, -- Nom
            TvcNIP = ISNULL(TuH.vcNIP, ''),
            TBirthDate = TuH.BirthDate, -- Date de naissance
            TDeathDate = TuH.DeathDate, -- Date du décès
            TSexID = TuH.SexID, -- Sexe (code)
            TLangID = TuH.LangID, -- Langue (code)
            TCivilID = TuH.CivilID, -- Statut civil (code)
            TSocialNumber = TuH.SocialNumber, -- Numéro d’assurance sociale
            TResidID = TuH.ResidID, -- Pays de résidence (code)
            TDriverLicenseNo = TuH.DriverLicenseNo, -- Numéro de permis
            TWebSite = TuH.WebSite, -- Site internet
            TCourtesyTitle = TuH.CourtesyTitle, -- Titre de courtoisie (Docteur, Professeur, etc.)
            TUsingSocialNumber = TuH.UsingSocialNumber, -- Droit d’utiliser le NAS.
            TSharePersonalInfo = TuH.SharePersonalInfo, -- Droit de partager les informations personnelles
            TMarketingMaterial = TuH.MarketingMaterial, -- Veux recevoir le matériel publicitaire.
            TIsCompany = TuH.IsCompany, -- Compagny ou humain
            TInForce = TuA.InForce, -- Date d’entrée en vigueur de l’adresse.
            TAdrTypeID = TuA.AdrTypeID, -- Type d’adresse (H = humain, C = Compagnie)
            TSourceID = TuA.SourceID, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
            TAddress = TuA.Address, -- # civique, rue et # d’appartement.
            TCity = TuA.City, -- Ville
            TStateName = TuA.StateName, -- Province
            TCountryID = TuA.CountryID, -- Pays (code)
            TZipCode = TuA.ZipCode, -- Code postal
            TPhone1 = TuA.Phone1, -- Tél. résidence
            TPhone2 = TuA.Phone2, -- Tél. bureau
            TFax = TuA.Fax, -- Fax
            TMobile = TuA.Mobile, -- Tél. cellulaire
            TWattLine = TuA.WattLine, -- Tél. sans frais
            TOtherTel = TuA.OtherTel, -- Autre téléphone.
            TPager = TuA.Pager, -- Paget
            TEmail = TuA.Email, -- Courriel
            fAvailableUnitQty = ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0),
            ConventionIDInd=C2.ConventionID, --Id convention individuelle RIO
            ConventionNoInd=C2.ConventionNo, --No convnetion individuelle RIO                        
            PaysOrigine = ISNULL(Corg.CountryName, ''), --Pays d'origine            
            PreferenceSuiviID = ISNULL(S.iID_Preference_Suivi, 0), --Preference suivi
            NoPersonnesaCharge=ISNULL(PS.tiNB_Personnes_A_Charge,0), --Ajout de la table tblCONV_ProfilSouscripteur
            ConnaisancePlacementID=ISNULL(PS.iID_Connaissance_Placements,0),
            RevenuFamilialID=ISNULL(PS.iID_Revenu_Familial,0),
            DepassementBaremeID=ISNULL(PS.iID_Depassement_Bareme,0),
            IdentiteSouscripteurID=ISNULL(S.iID_Identite_Souscripteur,0),
            ObjectifInvestissementLigne1ID=ISNULL(PS.iID_ObjectifInvestissementLigne1,0),
            ObjectifInvestissementLigne2ID=ISNULL(PS.iID_ObjectifInvestissementLigne2,0),
            ObjectifInvestissementLigne3ID=ISNULL(PS.iID_ObjectifInvestissementLigne3,0),
            IdentiteDescription=ISNULL(S.vcIdentiteVerifieeDescription,''),
            AutorisationResiliation=ISNULL(S.bAutorisation_Resiliation,0),
            DepassementJustification=ISNULL(PS.vcDepassementbaremeJustification,''),
            EstimationCoutEtudesID = ISNULL(PS.iID_Estimation_Cout_Etudes, 0),
            EstimationValeurNetteMenageID = ISNULL(PS.iID_Estimation_Valeur_Nette_Menage, 0),
            DestinationRemboursementID=ISNULL(C.iID_Destinataire_Remboursement, 0), --L'ID du Destination remboursement
            DestinationRemboursementAutre=ISNULL(C.vcDestinataire_Remboursement_Autre, ''), --Destination remboursement autre
            DateduProspectus=ISNULL(C.dtDateProspectus, ''), --Date du prospectus
            SouscripteurDesireIQEE=ISNULL(C.bSouscripteur_Desire_IQEE, 0), --Souscripteur desire IQEE
            C.tiID_Lien_CoSouscripteur,
            LienCoSouscripteur=ISNULL(LC.vcRelationshipType,''),
            C.iSous_Cat_ID_Resp_Prelevement,
            IDNiveauEtudeMere        = ISNULL(PS.iIDNiveauEtudeMere,    0),            -- 2010-01-06 : JFG :Modification des champs du profil souscripteur
            IDNiveauEtudePere        = ISNULL(PS.iIDNiveauEtudePere, 0),
            IDNiveauEtudeTuteur        = ISNULL(PS.iIDNiveauEtudeTuteur, 0),
            IDImportanceEtude        = ISNULL(PS.iIDImportanceEtude, 0),
            IDEpargneEtudeEnCours    = ISNULL(PS.iIDEpargneEtudeEnCours, 0),
            IDContributionFinanciereParent = ISNULL(PS.iIDContributionFinanciereParent,    0),
            IDConditionEligibleBenef = ISNULL(B.EligibilityConditionID, ''),
            R.iNumeroBDNI,
            C.bFormulaireRecu,
            C.dtRegStartDate,
            C.bSouscripteur_Desire_IQEE,
            IQEE        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            IQEEMaj        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            ConventionTypeInd            = S1.OperTypeID,                -- Type de la convention individuelle (RIO, RIM ou TRI)    
            vcOccupation                    = ISNULL(SH.vcOccupation, ''),                        -- Occupation de l'humain    
            vcEmployeur                        = ISNULL(SH.vcEmployeur, ''),                        -- Employeur de l'humain    
            tiNbAnneesService                = ISNULL(SH.tiNbAnneesService, ''),                    -- Nombre d'années de service    
            bRapport_Annuel_Direction        = ISNULL(S.bRapport_Annuel_Direction, 0),            -- Désire le rapport annuel de la direction
            bEtats_Financiers_Annuels        = ISNULL(S.bEtats_Financiers_Annuels, 0),            -- Désire les états financiers annuels    
            vcJustifObjectifsInvestissement    = ISNULL(PS.vcJustifObjectifsInvestissement, ''),    -- Justification du choix des objectifs d'investissement
            bEtats_Financiers_Semestriels    = ISNULL(S.bEtats_Financiers_Semestriels, 0),        -- Désire les états financiers semestriels    
            C.vcCommInstrSpec,
            iIDJustificationConvIncomplete = ISNULL(C.iID_Justification_Conv_Incomplete, 0),
--            bAImprimer                       = ISNULL(C.bAImprimer, 0),
            bStatutPortailSubscriber     = CASE when PAS.iUserId is NULL THEN 0 ELSE 1 END,
            bStatutPortailBeneficiary       = CASE when PAB.iUserId is NULL THEN 0 ELSE 1 END,
            DateRQ = dbo.fnIQEE_ObtenirDateEnregistrementRQ(C.ConventionID), 
              DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL), 
            DateFinRegimeOriginale = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'T', NULL),
            DateEntreeVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
            ,bConsentement_Souscripteur = CASE WHEN ISNULL(PAS.iEtat, 0) = 5 THEN CAST('1' AS bit) ELSE cast('0' AS bit) END 
            ,bConsentement_Beneficiaire = ISNULL(B.bReleve_Papier,0)  
            ,vcDossierBeneficiaire = GPB.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(BH.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(BH.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(BH.firstname)),' ','_') + '_' + cast(BH.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,vcDossierSouscripteur = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(sh.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(sh.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(sh.firstname)),' ','_') + '_' + cast(sh.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,ToleranceRisqueID=ISNULL(PS.iID_Tolerance_Risque,0)
        FROM Un_Rep R
        --JOIN dbo.Mo_Human RH ON RH.HumanID = R.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        JOIN Un_Rep RH_Rep ON RH_Rep.RepID = R.RepID
        LEFT JOIN dbo.Mo_Human RH ON RH.HumanID = RH_Rep.RepID
        LEFT JOIN dbo.Mo_Adr RA ON RA.AdrID = RH.AdrID
        LEFT JOIN dbo.Un_Subscriber S ON S.RepID = R.RepID
        LEFT JOIN dbo.Mo_Human SH ON SH.HumanID = S.SubscriberID
        LEFT JOIN dbo.Mo_Adr SA ON SA.AdrID = SH.AdrID
        LEFT JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID
        LEFT JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID
        LEFT JOIN (-- Date de vigueur enregistrée à la SCÉÉ #0768-07
            SELECT 
                G.ConventionID,
                InForceDate = MIN(G.dtTransaction)
            FROM Un_CESP100 G
            LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
            JOIN (-- Retourne la plus grande date de fichier scee envoyé par convention
                SELECT 
                    G.ConventionID,
                    dtCESPSendFile = MAX(ISNULL(SF.dtCESPSendFile, @Today))
                FROM Un_CESP100 G
                JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
                JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
                LEFT JOIN Un_CESPSendFile SF ON SF.iCESPSendFileID = G.iCESPSendFileID
                WHERE S.RepID = @MatrixID
                GROUP BY G.ConventionID
                ) V ON V.ConventionID = G.ConventionID AND ISNULL(S.dtCESPSendFile, @Today) = V.dtCESPSendFile
            GROUP BY G.ConventionID
            ) GGI ON GGI.ConventionID = C.ConventionID
        LEFT JOIN dbo.Mo_Human SHC ON SHC.HumanID = C.CoSubscriberID
        LEFT JOIN (-- point#729 
            SELECT 
                V1.SubscriberID, 
                TotalCapitalInsured = SubscribAmount - ISNULL(AmountToDate,0) 
            FROM (-- Retourne le total des montants versés par souscripteur
                SELECT 
                    C.SubscriberID, 
                    SubscribAmount = SUM(ROUND(M.PmtRate * U.UnitQty,2) * PmtQty)
                FROM dbo.Un_Convention C 
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID 
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
                WHERE S.RepID = @MatrixID
                  AND U.WantSubscriberInsurance <> 0
                  AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID 
                ) V1 
            LEFT JOIN ( -- Retourne les cotisations versées jusqu'à présent par souscripteurs
                SELECT 
                    C.SubscriberID, 
                    AmountToDate = SUM(Co.Cotisation + Co.Fee)
                FROM dbo.Un_Convention C 
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
                WHERE S.RepID = @MatrixID
                  AND U.WantSubscriberInsurance <> 0
                  AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID 
                ) V2 ON V1.SubscriberID = V2.SubscriberID
            ) TC ON TC.SubscriberID = S.SubscriberID
        LEFT JOIN (-- Retourne la somme des intérêts sur montant souscrit par convention
            SELECT
                CO.ConventionID,
                CapitalInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
              AND CO.ConventionOperTypeID = 'INM'
            GROUP BY CO.ConventionID
            ) CI ON CI.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des intérêts sur subvention par convention
            SELECT
                CO.ConventionID,
                GrantInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
              AND CHARINDEX(','+CO.ConventionOperTypeID+',',@vcCONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION) > 0
            GROUP BY CO.ConventionID
            ) CG ON CG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des frais disponibles par convention
            SELECT
                CO.ConventionID,
                AvailableFeeAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
              AND CO.ConventionOperTypeID = 'FDI'
            GROUP BY CO.ConventionID
            ) CF ON CF.ConventionID = C.ConventionID
        LEFT JOIN Un_Plan PC ON PC.PlanID = C.PlanID
        LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
        LEFT JOIN Un_Modal M ON M.ModalID = U.ModalID
        LEFT JOIN Un_Plan P ON P.PlanID = M.PlanID
        LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
        LEFT JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
        --LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = U.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep UR_Rep ON UR_Rep.RepID = U.RepID
        LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = UR_Rep.RepID
        --LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = U.RepResponsableID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep URR_Rep ON URR_Rep.RepID = U.RepResponsableID
        LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = URR_Rep.RepID
        LEFT JOIN dbo.Mo_Adr BA ON BA.AdrID = BH.AdrID
        LEFT JOIN (-- Retourne le total des cotisations et de frais ainsi que la plus petite date d'opération par unités
            SELECT
                Ct.UnitID,
                OperDate = MIN(O.OperDate),
                FEE = SUM(Ct.Fee),
                Cotisation = SUM(Ct.Cotisation)
            FROM Un_Cotisation Ct
            JOIN Un_Oper O ON O.OperID = Ct.OperID
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
            WHERE S.RepID = @MatrixID
                AND(    ( O.OperTypeID = 'CPA' 
                         AND ISNULL(OBF.OperID, 0) > 0
                        )
                    OR O.OperDate < = GETDATE()
                    )
            GROUP BY Ct.UnitID
            ) Ct ON Ct.UnitID = U.UnitID
        LEFT JOIN (-- Sert à la détection d'un arrêt de paiement sur le groupe d'unité
            SELECT DISTINCT 
                H.UnitID 
            FROM Un_UnitHoldPayment H
            JOIN dbo.Un_Unit U ON U.UnitID = H.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
                AND H.StartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(H.EndDate,0) <= 0
                        OR H.EndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) UHP ON UHP.UnitID = U.UnitID
        LEFT JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne l'info des banques
            SELECT
                B.BankID,
                B.BankTransit,
                BankName = C.CompanyName,
                BT.BankTypeName,
                BT.BankTypeCode
            FROM Mo_Bank B
            JOIN Mo_Company C ON C.CompanyID = B.BankID
            JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
            ) BK ON BK.BankID = CA.BankID
        LEFT JOIN Un_Program Prog ON Prog.ProgramID = B.ProgramID
        LEFT JOIN Un_College Co ON Co.CollegeID = B.CollegeID
        LEFT JOIN Mo_Company CoCo ON CoCo.CompanyID = Co.CollegeID
        LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
        LEFT JOIN Mo_State St ON St.StateID = S.StateID
        LEFT JOIN (-- Retourne les conventions en arrêt de paiement
            SELECT DISTINCT
                B.ConventionID
            FROM Un_Breaking B
            JOIN dbo.Un_Convention C ON C.ConventionID = B.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
                AND B.BreakingStartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(B.BreakingEndDate,0) <= 0
                        OR B.BreakingEndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) BKG ON BKG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne le nombre de dépôts par unité
            SELECT
                A.UnitID,
                AutomaticDepositCount = COUNT(A.AutomaticDepositID)
            FROM Un_AutomaticDeposit A
            JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
                AND    ( dbo.FN_CRQ_DateNoTime(GETDATE()) BETWEEN A.StartDate AND A.EndDate
                         OR    ( dbo.FN_CRQ_DateNoTime(GETDATE()) >= A.StartDate 
                                AND ISNULL(A.EndDate,0) < 2
                                )
                        )
            GROUP BY A.UnitID
            ) AD ON AD.UnitID = U.UnitID
        LEFT JOIN (-- Retourne le nombre de nsf par convention
            SELECT
                U.ConventionID,
                NbNSF = COUNT(DISTINCT O.OperID)
            FROM Mo_BankReturnLink R
            JOIN Un_Oper O ON O.OperID = R.BankReturnCodeID
            JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
              AND R.BankReturnTypeID = '901'
            GROUP BY U.ConventionID
            ) NSF ON NSF.ConventionID = C.ConventionID
        LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
        LEFT JOIN (-- 10.23.1 (2.2) : Retrouve l'état actuel d'une convention
            SELECT 
                T.ConventionID,
                CS.ConventionStateID,
                CS.ConventionStateName
            FROM (-- Retourne la plus grande date de début d'un état par convention
                SELECT 
                    S.ConventionID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_ConventionConventionState S
                JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
                JOIN dbo.Un_Subscriber Sub ON Sub.SubscriberID = C.SubscriberID
                WHERE Sub.RepID = @MatrixID
                  AND S.StartDate <= GETDATE()
                GROUP BY S.ConventionID
                ) T
            JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
            JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
            ) CS ON C.ConventionID = CS.ConventionID
        LEFT JOIN (-- 10.23.1 (3.2) : Retrouve l'état actuel d'un groupe d'unités
            SELECT 
                T.UnitID,
                US.UnitStateID,
                US.UnitStateName
            FROM (-- Retourne la plus grande date de début d'un état par unité
                SELECT 
                    S.UnitID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_UnitUnitState S
                JOIN dbo.Un_Unit U ON U.UnitID = S.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Subscriber Sub ON Sub.SubscriberID = C.SubscriberID
                WHERE Sub.RepID = @MatrixID
                  AND S.StartDate <= GETDATE()
                GROUP BY S.UnitID
                ) T
            JOIN Un_UnitUnitState UUS ON T.UnitID = UUS.UnitID AND T.MaxDate = UUS.StartDate -- Retrouve l'état correspondant à la plus grande date par unité
            JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID -- Pour retrouver la description de l'état
            ) US ON U.UnitID = US.UnitID
        LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
            SELECT
                U.ConventionID,
                MonthTheoricAmount = 
                    SUM(
                        ROUND(M.PmtRate * U.UnitQty,2) + -- Cotisation et frais
                        dbo.FN_CRQ_TaxRounding
                            ((    CASE U.WantSubscriberInsurance -- Assurance souscripteur
                                    WHEN 0 THEN 0
                                ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
                                END +
                                ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
                            (1+ISNULL(St.StateTaxPct,0)))) -- Taxes
            FROM dbo.Un_Unit U
            JOIN Un_Modal M ON U.ModalID = M.ModalID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            LEFT JOIN Mo_State St ON St.StateID = S.StateID
            LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
            LEFT JOIN (
                SELECT
                    U.UnitID,
                    CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
                FROM dbo.Un_Unit U
                JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
                WHERE S.RepID = @MatrixID
                GROUP BY U.UnitID
                ) Ct ON U.UnitID = Ct.UnitID
            WHERE S.RepID = @MatrixID
              AND M.PmtByYearID = 12
              AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
            GROUP BY U.ConventionID
            ) AMT ON C.ConventionID = AMT.ConventionID 
        LEFT JOIN CRQ_WorldLang W ON S.BirthLangID = W.WorldLanguageCodeID
        LEFT JOIN (
            SELECT
                M.UnitID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    U.UnitID,
                    U.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Unit U
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
                JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
                JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
                JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
                WHERE S.RepID = @MatrixID
                GROUP BY U.UnitID, U.RepID
                ) M
            JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
            WHERE S.RepID = @MatrixID
            GROUP BY M.UnitID
            ) UDIR ON UDIR.UnitID = U.UnitID
        LEFT JOIN dbo.Mo_Human HUDIR ON HUDIR.HumanID = UDIR.BossID
        LEFT JOIN (
            SELECT
                M.RepID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    R.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM Un_Rep R
                JOIN Un_RepBossHist RBH ON RBH.RepID = R.RepID AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
                JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
                JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)
                WHERE R.RepID = @MatrixID
                GROUP BY R.RepID
                ) M
            JOIN Un_Rep R ON R.RepID = M.RepID
            JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
            WHERE R.RepID = @MatrixID
            GROUP BY M.RepID
            ) RDIR ON RDIR.RepID = R.RepID
        LEFT JOIN dbo.Mo_Human HRDIR ON HRDIR.HumanID = RDIR.BossID
        LEFT JOIN (
            SELECT 
                CE.ConventionID,
                fCESG = SUM(CE.fCESG),
                fACESG = SUM(CE.fACESG),
                fCLB = SUM(CE.fCLB)
            FROM Un_CESP CE
            JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = @MatrixID
            GROUP BY CE.ConventionID
            ) GG ON GG.ConventionID = C.ConventionID
        --LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID
        LEFT JOIN Un_Tutor Tu ON Tu.iTutorID = B.iTutorID AND B.bTutorIsSubscriber = 0
        LEFT JOIN dbo.Mo_Human TuH ON TuH.HumanID = B.iTutorID
        LEFT JOIN dbo.Mo_Adr TuA ON TuA.AdrID = TuH.AdrID
        LEFT JOIN ( -- Unité résiliés
                SELECT 
                    U.ConventionID, 
                    UnitRes = SUM(UR.UnitQty)
                FROM Un_UnitReduction UR
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
                WHERE S.RepID = @MatrixID
                GROUP BY U.ConventionID) SR ON SR.ConventionID = C.ConventionID
        LEFT JOIN ( -- Unité utilisés
                SELECT 
                    U.ConventionID, 
                    UnitUse = SUM(A.fUnitQtyUse)
                FROM Un_UnitReduction UR
                JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID        
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
                WHERE S.RepID = @MatrixID
                GROUP BY U.ConventionID) SU ON SU.ConventionID = C.ConventionID
        LEFT JOIN @tUn_MaxConvDepositDateCfg MCD ON U.InForceDate BETWEEN MCD.dtStart AND MCD.dtEnd

        LEFT JOIN (SELECT iID_Convention_Source,iID_Convention_Destination = min(iID_Convention_Destination), iID_Unite_Source, TOPER.OperTypeID
                    FROM tblOPER_OperationsRIO TOPER 
                    WHERE (TOPER.bRIO_ANNULEE = 0 AND TOPER.bRIO_QUIANNULE = 0)
                    GROUP BY iID_Convention_Source, iID_Unite_Source, TOPER.OperTypeID) AS S1 ON S1.iID_Convention_Source = C.ConventionID  AND S1.iID_Unite_Source = U.UnitID

        LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = S1.iID_Convention_Destination
        LEFT JOIN Mo_Country Corg ON Corg.CountryID = SH.cID_Pays_Origine --Pays d'origine
        LEFT JOIN Un_RelationshipType LC ON LC.tiRelationshipTypeID = C.tiID_Lien_CoSouscripteur
        LEFT JOIN tblCONV_PreferenceSuivi Prf ON PRF.iID_Preference_Suivi = S.iID_Preference_Suivi --Preference suivi
        LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID AND PS.DateProfilInvestisseur = (
            SELECT    
                MAX(PSM.DateProfilInvestisseur)
            FROM tblCONV_ProfilSouscripteur PSM
            WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
                AND PSM.DateProfilInvestisseur <= GETDATE()
            )
        LEFT JOIN tblGENE_PortailAuthentification PAS ON PAS.iUserId = S.SubscriberID 
        LEFT JOIN tblGENE_PortailAuthentification PAB ON PAB.iUserId = B.BeneficiaryID
        LEFT JOIN tblGENE_TypesParametre GTPB on GTPB.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE'
        LEFT JOIN tblGENE_Parametres GPB ON GTPB.iID_Type_Parametre = GPB.iID_Type_Parametre
        LEFT JOIN tblGENE_TypesParametre GTPS on GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR'
        LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
        LEFT JOIN (
            SELECT r.iID_Convention_Destination
            from tblOPER_OperationsRIO r
            WHERE r.OperTypeID IN ('RIO', 'RIM')
            AND r.bRIO_QuiAnnule = 0
            GROUP BY r.iID_Convention_Destination
                )FBU ON C.ConventionID = FBU.iID_Convention_Destination
        WHERE R.RepID = @MatrixID
        ORDER BY
            RH.LastName,
            RH.FirstName,
            SH.LastName,
            SH.FirstName,
            C.ConventionNo,
            BH.LastName,
            BH.FirstName
    END -- ELSE IF (@MatrixType = 'REP') 
    ELSE IF @MatrixType = 'TUT' -- Tuteur
    BEGIN
        SELECT
            S.SubscriberID,
            S.RepID,
            /*SRepName = 
                CASE 
                    WHEN R.HumanID IS NULL THEN ''
                    ELSE R.LastName + ', ' + R.FirstName
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            SRepName = CASE WHEN R_Rep.BusinessEnd IS NULL THEN 
                    CASE WHEN R.HumanID IS NULL THEN '' ELSE R.LastName + ', ' + R.FirstName + ' (' + R_Rep.Repcode + ')' END
                   ELSE CASE WHEN R.HumanID IS NULL THEN '' ELSE R.LastName + ', ' + R.FirstName + ' (' + R_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            S.ScholarshipLevelID,
            S.AnnualIncome,
            S.StateID,
            S.SemiAnnualStatement,
            SFirstName = SH.FirstName,
            SOrigName = SH.OrigName,
            SLastName = SH.LastName,
            SvcNIP = ISNULL(SH.vcNIP, ''),
            SCompanyName = SH.CompanyName,
            SSexID = SH.SexID,
            SAdrID = SH.AdrID,
            SBirthDate = SH.BirthDate,
            SDeathDate = SH.DeathDate,
            SLangID = SH.LangID,
            SCivilID = SH.CivilID,
            SCourtesyTitle = SH.CourtesyTitle,
            SUsingSocialNumber = SH.UsingSocialNumber,
            SSharePersonalInfo = SH.SharePersonalInfo,
            SMarketingMaterial = SH.MarketingMaterial,
            SIsCompany = SH.IsCompany,
            SSocialNumber = SH.SocialNumber,
            SDriverLicenseNo = SH.DriverLicenseNo,
            SWebSite = SH.WebSite,
            SResidID = SH.ResidID,
            SInForce = SA.InForce,
            SAdrTypeID = SA.AdrTypeID,
            SSourceID = SA.SourceID,
            SAddress = SA.Address,
            SCity = SA.City,
            SStateName = SA.StateName,
            SCountryID = SA.CountryID,
            SZipCode = SA.ZipCode,
            SPhone1 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone1, SA.CountryID),
            SPhone2 = dbo.FN_CRQ_FormatPhoneNo(SA.Phone2, SA.CountryID),
            SFax = dbo.FN_CRQ_FormatPhoneNo(SA.Fax, SA.CountryID),
            SMobile = dbo.FN_CRQ_FormatPhoneNo(SA.Mobile, SA.CountryID),
            SWattLine = dbo.FN_CRQ_FormatPhoneNo(SA.WattLine, SA.CountryID),
            SOtherTel = dbo.FN_CRQ_FormatPhoneNo(SA.OtherTel, SA.CountryID),
            SPager = dbo.FN_CRQ_FormatPhoneNo(SA.Pager, SA.CountryID),
            SEMail = SA.EMail,
            tiSubsCESPState = S.tiCESPState, -- État du souscripteur au niveau des pré-validations. (0 = Rien ne passe et 1 = La SCEE passe)
            Spouse = ISNULL(S.Spouse,''),
            Contact1 = ISNULL(S.Contact1,''),
            Contact2 = ISNULL(S.Contact2,''),
            Contact1Phone = ISNULL(S.Contact1Phone,''),
            Contact2Phone = ISNULL(S.Contact2Phone,''),        
            SNEQ = ISNULL(SH.StateCompanyNo,''),
            bSouscripteur_Desire_Releve_Elect = ISNULL(S.bReleve_Papier,0), 
            bSouscripteur_Accepte_Publipostage = SH.bHumain_Accepte_Publipostage,
            B.BeneficiaryID,
            B.GovernmentGrantForm,
            B.BirthCertificate,
            B.PersonalInfo,
            B.ProgramID,
            B.ProgramLength,
            B.ProgramYear,
            B.SchoolReport,
            B.RegistrationProof,
            B.StudyStart,
            B.CaseOfJanuary,
            B.EligibilityQty,
            B.CollegeID,
            bBeneficiaryAddressLost = B.bAddressLost,
            tiPCGType =
                CASE 
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 0 THEN 0
                    WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 1 THEN 1
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 1 THEN 2
                    WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 0 THEN 3
                END, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise-Souscripteur, 3=Entreprise)
            B.vcPCGFirstName, -- Prénom du principal responsable s’il s’agit d’un souscripteur ou d’une personne. Nom de l’entreprise principal responsable dans l’autre cas.
            B.vcPCGLastName, -- Nom du principal responsable s’il s’agit d’un souscripteur ou d’une personne.
            B.vcPCGSINOrEN, -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
            bBeneficiaire_Accepte_Publipostage = BH.bHumain_Accepte_Publipostage,
            tiBenefCESPState = B.tiCESPState,
            Co.CollegeTypeID,
            B.EligibilityConditionID,
            Co.CollegeCode,
            CollegeName = CoCo.CompanyName,
            Prog.ProgramDesc,
            BFirstName = BH.FirstName,
            BOrigName = BH.OrigName,
            BInitial = BH.Initial,
            BLastName = BH.LastName,
            BvcNIP = ISNULL(BH.vcNIP, ''),
            BCompanyName = BH.CompanyName,
            BSexID = BH.SexID,
            BAdrID = BH.AdrID,
            BBirthDate = BH.BirthDate,
            BDeathDate = BH.DeathDate,
            BLangID = BH.LangID,
            BCivilID = BH.CivilID,
            BCourtesyTitle = BH.CourtesyTitle,
            BUsingSocialNumber = BH.UsingSocialNumber,
            BSharePersonalInfo = BH.SharePersonalInfo,
            BMarketingMaterial = BH.MarketingMaterial,
            BIsCompany = BH.IsCompany,
            BSocialNumber = BH.SocialNumber,
            BDriverLicenseNo = BH.DriverLicenseNo,
            BWebSite = BH.WebSite,
            BResidID = BH.ResidID,
            BNEQ = ISNULL(BH.StateCompanyNo,''),
            BInForce = BA.InForce,
            BAdrTypeID = BA.AdrTypeID,
            BSourceID = BA.SourceID,
            BAddress = BA.Address,
            BCity = BA.City,
            BStateName = BA.StateName,
            BCountryID = BA.CountryID,
            BZipCode = BA.ZipCode,
            BPhone1 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone1, BA.CountryID),
            BPhone2 = dbo.FN_CRQ_FormatPhoneNo(BA.Phone2, BA.CountryID),
            BFax = dbo.FN_CRQ_FormatPhoneNo(BA.Fax, BA.CountryID),
            BMobile = dbo.FN_CRQ_FormatPhoneNo(BA.Mobile, BA.CountryID),
            BWattLine = dbo.FN_CRQ_FormatPhoneNo(BA.WattLine, BA.CountryID),
            BOtherTel = dbo.FN_CRQ_FormatPhoneNo(BA.OtherTel, BA.CountryID),
            BPager = dbo.FN_CRQ_FormatPhoneNo(BA.Pager, BA.CountryID),
            BEMail = BA.EMail,
            C.ConventionID,
            C.ConventionNo,
            C.YearQualif,
            C.tiMaximisationREEE,
            PmtDate = C.FirstPmtDate,
            C.PmtTypeID,
            C.tiRelationshipTypeID,
            RT.vcRelationshipType,
            C.GovernmentRegDate,
            C.ScholarshipYear,
            C.ScholarshipEntryID,
            C.dtRegEndDateAdjust,
            dtConvInforceDateTIN = C.dtInforceDateTIN,
            C.CoSubscriberID,
            CPlanID = PC.PlanID,
            CPlanTypeID = PC.PlanTypeID,
            CPlanDesc = PC.PlanDesc,
            C.bTuteur_Desire_Releve_Elect,
            U.UnitID,
            U.UnitQty,
            U.InForceDate,
            U.SignatureDate,
            U.TerminatedDate,
            U.IntReimbDate,
            U.ActivationConnectID,
            U.ValidationConnectID,
            U.BenefInsurID,
            U.WantSubscriberInsurance,
            URepID = U.RepID,
            /*URepName = 
                CASE ISNULL(U.RepID,0) 
                    WHEN 0 THEN '' 
                ELSE UR.LastName + ', ' + UR.FirstName 
                END, 
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepName = CASE WHEN UR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE UR.LastName + ', ' + UR.FirstName + ' (' + UR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            URepResponsableID = U.RepResponsableID,
            U.PmtEndConnectID,
            U.IntReimbDateAdjust,
            /*URepResponsableName = 
                CASE ISNULL(U.RepResponsableID,0) 
                    WHEN 0 THEN '' 
                ELSE URR.LastName + ', ' + URR.FirstName 
                END,
            Ligne remplacée par celle ci-dessous pour ajouter le mot inactif lorsqu'il y a une date de fin de contrat*/
            URepResponsableName = CASE WHEN URR_Rep.BusinessEnd IS NULL THEN 
                    CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' END
                   ELSE CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE URR.LastName + ', ' + URR.FirstName + ' (' + URR_Rep.Repcode + ')' + ' (Inactif)' END 
                   END,
            U.StopRepComConnectID,
            U.SubscribeAmountAjustment,
            U.LastDepositForDoc,
            U.dtCotisationEndDateAdjust,
            U.dtInforceDateTIN,
            U.iSous_Cat_ID,
            MCD.YearQty,
            M.ModalID,
            M.ModalDate,
            M.PmtByYearID,
            M.PmtQty,
            M.PmtRate,
            M.SubscriberInsuranceRate,
            M.BenefAgeOnBegining,
            FeeByUnit = CASE WHEN FBU.iID_Convention_Destination IS NULL THEN  M.FeeByUnit ELSE 0 END,
            M.FeeSplitByUnit,
            M.FeeRefundable,
            P.tiAgeQualif,
            M.BusinessBonusToPay,
            BI.BenefInsurDate,
            BI.BenefInsurFaceValue,
            BI.BenefInsurPmtByYear,
            BI.BenefInsurRate,
            P.PlanID,
            P.PlanDesc,
            P.PlanTypeID,
            P.IntReimbAge,
            CA.BankID,
            CA.AccountName,
            CA.TransitNo,
            BK.BankTransit,
            BK.BankName,
            BK.BankTypeName,
            BK.BankTypeCode,
            ConventionBreaking = ISNULL(Bkg.ConventionID,0),
            UnitHoldPayment = ISNULL(uhp.UnitID,0),
            StateTaxPct = ISNULL(St.StateTaxPct,0),
            FirstPmtDate = Ct.OperDate,
            Cotisation = ISNULL(Ct.Cotisation, 0),
            Fee = ISNULL(Ct.Fee, 0),
            CapitalInterestAmount = ISNULL(CI.CapitalInterestAmount, 0),
            GrantInterestAmount = ISNULL(CG.GrantInterestAmount, 0),
            AvailableFeeAmount = ISNULL(CF.AvailableFeeAmount, 0),
            AutomaticDepositCount = ISNULL(AD.AutomaticDepositCount, 0),
            CoSubscriberName = 
                CASE 
                    WHEN ISNULL(C.CoSubscriberID, 0) = 0 THEN '' 
                    WHEN SHC.IsCompany = 1 THEN SHC.LastName
                ELSE SHC.LastName + ', ' + SHC.FirstName 
                END,
            NbNSF = ISNULL(NSF.NbNSF,0),
            SS.SaleSourceID, --point 718
            SS.SaleSourceDesc, --point 718
            bIsContestWinner = ISNULL(SS.bIsContestWinner,0),
            TotalCapitalInsured = 
                CASE 
                    WHEN ISNULL(TC.TotalCapitalInsured,0) > 0 THEN TC.TotalCapitalInsured 
                ELSE 0 
                END, -- point#729
            CESGInForceDate = GGI.InForceDate, -- #0768-05
            CS.ConventionStateID,
            CS.ConventionStateName,
            US.UnitStateID,
            US.UnitStateName,
            AutoMonthTheoricAmount = 
                CASE ISNULL(C.PmtTypeID, '') 
                    WHEN 'AUT' THEN ISNULL(AMT.MonthTheoricAmount,0) 
                END, -- Valeur retournée seulement si paiement automatique
            BirthLangID = ISNULL(WorldLanguageCodeID,''),
            BirthLangName = ISNULL(WorldLanguage,''),
            S.AddressLost,
            UDirName = 
                CASE ISNULL(UDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HUDIR.LastName + ', ' + HUDIR.FirstName 
                END,
            SDirName = 
                CASE ISNULL(SDIR.BossID,0) 
                    WHEN 0 THEN '' 
                ELSE HSDIR.LastName + ', ' + HSDIR.FirstName 
                END,
            C.bSendToCESP, -- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
            fCESG = ISNULL(GG.fCESG,0), -- Solde du compte de SCEE de la convention.
            fACESG = ISNULL(GG.fACESG,0), -- Solde du compte de SCEE+ de la convention.
            fCLB = ISNULL(GG.fCLB,0), -- Solde du compte de BEC de la convention.
            C.bCESGRequested, -- SCEE voulue (1) ou non (2)
            C.bACESGRequested, -- SCEE+ voulue (1) ou non (2)
            C.bCLBRequested, -- BEC voulu (1) ou non (2)
            C.tiCESPState, -- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
            DiplomaTextID = 9999, -- DT.DiplomaTextID,  -- ID unique du texte du diplôme        -- 2015-07-29
            DiplomaText = ISNULL(C.TexteDiplome, ''), -- DT.DiplomaText, -- Texte du diplôme        -- 2015-07-29
            Tu.iTutorID, -- ID du tuteur, correspond au HumanID.
            B.bTutorIsSubscriber, -- Si le Tuteur est un souscripteur ou non
            TvcEN = Tu.vcEN, -- Numéro d’entreprise, si le tuteur en est une.
            TFirstName = TuH.FirstName, -- Prénom du tuteur
            TOrigName = TuH.OrigName, -- Nom à la naissance
            TInitial = TuH.Initial, -- Initial (Jr, Sr, etc.)
            TLastName = TuH.LastName, -- Nom
            TvcNIP = ISNULL(TuH.vcNIP, ''),
            TBirthDate = TuH.BirthDate, -- Date de naissance
            TDeathDate = TuH.DeathDate, -- Date du décès
            TSexID = TuH.SexID, -- Sexe (code)
            TLangID = TuH.LangID, -- Langue (code)
            TCivilID = TuH.CivilID, -- Statut civil (code)
            TSocialNumber = TuH.SocialNumber, -- Numéro d’assurance sociale
            TResidID = TuH.ResidID, -- Pays de résidence (code)
            TDriverLicenseNo = TuH.DriverLicenseNo, -- Numéro de permis
            TWebSite = TuH.WebSite, -- Site internet
            TCourtesyTitle = TuH.CourtesyTitle, -- Titre de courtoisie (Docteur, Professeur, etc.)
            TUsingSocialNumber = TuH.UsingSocialNumber, -- Droit d’utiliser le NAS.
            TSharePersonalInfo = TuH.SharePersonalInfo, -- Droit de partager les informations personnelles
            TMarketingMaterial = TuH.MarketingMaterial, -- Veux recevoir le matériel publicitaire.
            TIsCompany = TuH.IsCompany, -- Compagny ou humain
            TInForce = TuA.InForce, -- Date d’entrée en vigueur de l’adresse.
            TAdrTypeID = TuA.AdrTypeID, -- Type d’adresse (H = humain, C = Compagnie)
            TSourceID = TuA.SourceID, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
            TAddress = TuA.Address, -- # civique, rue et # d’appartement.
            TCity = TuA.City, -- Ville
            TStateName = TuA.StateName, -- Province
            TCountryID = TuA.CountryID, -- Pays (code)
            TZipCode = TuA.ZipCode, -- Code postal
            TPhone1 = TuA.Phone1, -- Tél. résidence
            TPhone2 = TuA.Phone2, -- Tél. bureau
            TFax = TuA.Fax, -- Fax
            TMobile = TuA.Mobile, -- Tél. cellulaire
            TWattLine = TuA.WattLine, -- Tél. sans frais
            TOtherTel = TuA.OtherTel, -- Autre téléphone.
            TPager = TuA.Pager, -- Paget
            TEmail = TuA.Email, -- Courriel
            fAvailableUnitQty = ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0),
            ConventionIDInd=C2.ConventionID, --Id convention individuelle RIO
            ConventionNoInd=C2.ConventionNo, --No convnetion individuelle RIO                    
            PaysOrigine = ISNULL(Corg.CountryName, ''), --Pays d'origine            
            PreferenceSuiviID = ISNULL(S.iID_Preference_Suivi, 0), --Preference suivi
            NoPersonnesaCharge=ISNULL(PS.tiNB_Personnes_A_Charge,0), --Ajout de la table tblCONV_ProfilSouscripteur
            ConnaisancePlacementID=ISNULL(PS.iID_Connaissance_Placements,0),
            RevenuFamilialID=ISNULL(PS.iID_Revenu_Familial,0),
            DepassementBaremeID=ISNULL(PS.iID_Depassement_Bareme,0),
            IdentiteSouscripteurID=ISNULL(S.iID_Identite_Souscripteur,0),
            ObjectifInvestissementLigne1ID=ISNULL(PS.iID_ObjectifInvestissementLigne1,0),
            ObjectifInvestissementLigne2ID=ISNULL(PS.iID_ObjectifInvestissementLigne2,0),
            ObjectifInvestissementLigne3ID=ISNULL(PS.iID_ObjectifInvestissementLigne3,0),
            IdentiteDescription=ISNULL(S.vcIdentiteVerifieeDescription,''),
            AutorisationResiliation=ISNULL(S.bAutorisation_Resiliation,0),
            DepassementJustification=ISNULL(PS.vcDepassementbaremeJustification,''),
            EstimationCoutEtudesID = ISNULL(PS.iID_Estimation_Cout_Etudes, 0),
            EstimationValeurNetteMenageID = ISNULL(PS.iID_Estimation_Valeur_Nette_Menage, 0),
            DestinationRemboursementID=ISNULL(C.iID_Destinataire_Remboursement, 0), --L'ID du Destination remboursement
            DestinationRemboursementAutre=ISNULL(C.vcDestinataire_Remboursement_Autre, ''), --Destination remboursement autre
            DateduProspectus=ISNULL(C.dtDateProspectus, ''), --Date du prospectus
            SouscripteurDesireIQEE=ISNULL(C.bSouscripteur_Desire_IQEE, 0), --Souscripteur desire IQEE
            C.tiID_Lien_CoSouscripteur,
            LienCoSouscripteur=ISNULL(LC.vcRelationshipType,''),
            C.iSous_Cat_ID_Resp_Prelevement,
            IDNiveauEtudeMere        = ISNULL(PS.iIDNiveauEtudeMere,    0),            -- 2010-01-06 : JFG :Modification des champs du profil souscripteur
            IDNiveauEtudePere        = ISNULL(PS.iIDNiveauEtudePere, 0),
            IDNiveauEtudeTuteur        = ISNULL(PS.iIDNiveauEtudeTuteur, 0),
            IDImportanceEtude        = ISNULL(PS.iIDImportanceEtude, 0),
            IDEpargneEtudeEnCours    = ISNULL(PS.iIDEpargneEtudeEnCours, 0),
            IDContributionFinanciereParent = ISNULL(PS.iIDContributionFinanciereParent,    0),
            IDConditionEligibleBenef = ISNULL(B.EligibilityConditionID, ''),
            R_Rep.iNumeroBDNI,
            C.bFormulaireRecu,
            C.dtRegStartDate,
            C.bSouscripteur_Desire_IQEE,
            IQEE        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            IQEEMaj        =    ISNULL((SELECT SUM    (ISNULL(COP.ConventionOperAmount,0))
                            FROM
                                dbo.Un_ConventionOper COP
                            WHERE
                                COP.ConventionID = C.ConventionID
                                AND 
                                EXISTS
                                (SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
            ConventionTypeInd            = S1.OperTypeID,                -- Type de la convention individuelle (RIO, RIM ou TRI)    
            vcOccupation                    = ISNULL(SH.vcOccupation, ''),                        -- Occupation de l'humain    
            vcEmployeur                        = ISNULL(SH.vcEmployeur, ''),                        -- Employeur de l'humain    
            tiNbAnneesService                = ISNULL(SH.tiNbAnneesService, ''),                    -- Nombre d'années de service    
            bRapport_Annuel_Direction        = ISNULL(S.bRapport_Annuel_Direction, 0),            -- Désire le rapport annuel de la direction
            bEtats_Financiers_Annuels        = ISNULL(S.bEtats_Financiers_Annuels, 0),            -- Désire les états financiers annuels    
            vcJustifObjectifsInvestissement    = ISNULL(PS.vcJustifObjectifsInvestissement, ''),    -- Justification du choix des objectifs d'investissement
            bEtats_Financiers_Semestriels    = ISNULL(S.bEtats_Financiers_Semestriels, 0),        -- Désire les états financiers semestriels    
            C.vcCommInstrSpec,
            iIDJustificationConvIncomplete = ISNULL(C.iID_Justification_Conv_Incomplete, 0),
--            bAImprimer                       = ISNULL(C.bAImprimer, 0),
            bStatutPortailSubscriber       = CASE when PAS.iUserId is NULL THEN 0 ELSE 1 END,
            bStatutPortailBeneficiary       = CASE when PAB.iUserId is NULL THEN 0 ELSE 1 END,
            DateRQ = dbo.fnIQEE_ObtenirDateEnregistrementRQ(C.ConventionID), 
              DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL), 
            DateFinRegimeOriginale = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'T', NULL),
            DateEntreeVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
            ,bConsentement_Souscripteur = CASE WHEN ISNULL(PAS.iEtat, 0) = 5 THEN CAST('1' AS bit) ELSE cast('0' AS bit) END 
            ,bConsentement_Beneficiaire = ISNULL(B.bReleve_Papier,0)  
            ,vcDossierBeneficiaire = GPB.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(BH.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(BH.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(BH.firstname)),' ','_') + '_' + cast(BH.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,vcDossierSouscripteur = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(sh.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(sh.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(sh.firstname)),' ','_') + '_' + cast(sh.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
            ,ToleranceRisqueID=ISNULL(PS.iID_Tolerance_Risque,0)
        FROM Un_Tutor Tu 
        JOIN dbo.Mo_Human TuH ON TuH.HumanID = Tu.iTutorID
        LEFT JOIN dbo.Mo_Adr TuA ON TuA.AdrID = TuH.AdrID
        LEFT JOIN dbo.Un_Beneficiary B ON Tu.iTutorID = B.iTutorID AND B.bTutorIsSubscriber = 0
        LEFT JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
        LEFT JOIN dbo.Mo_Adr BA ON BA.AdrID = BH.AdrID
        LEFT JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
        LEFT JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID
        LEFT JOIN (-- Date de vigueur enregistrée à la SCÉÉ #0768-07
            SELECT 
                G.ConventionID,
                InForceDate = MIN(G.dtTransaction) 
            FROM Un_CESP100 G
            LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
            JOIN (-- Retourne la plus grande date de fichier scee envoyé par convention
                SELECT 
                    G.ConventionID,
                    dtCESPSendFile = MAX(ISNULL(S.dtCESPSendFile, @Today))
                FROM Un_CESP100 G
                JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                GROUP BY G.ConventionID
                ) V ON V.ConventionID = G.ConventionID AND ISNULL(S.dtCESPSendFile, @Today) = V.dtCESPSendFile
            GROUP BY G.ConventionID
            ) GGI ON GGI.ConventionID = C.ConventionID
        LEFT JOIN dbo.Mo_Human SHC ON SHC.HumanID = C.CoSubscriberID
        LEFT JOIN (-- Retourne la somme des intérêts sur montant souscrit par convention
            SELECT
                CO.ConventionID,
                CapitalInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND CO.ConventionOperTypeID = 'INM'
            GROUP BY CO.ConventionID
            ) CI ON CI.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des intérêts sur subvention par convention
            SELECT
                CO.ConventionID,
                GrantInterestAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND CHARINDEX(','+CO.ConventionOperTypeID+',',@vcCONV_CONSULTATION_MONTANTS_RENDEMENTS_SUBVENTION) > 0
            GROUP BY CO.ConventionID
            ) CG ON CG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne la somme des frais disponibles par convention
            SELECT
                CO.ConventionID,
                AvailableFeeAmount = SUM(CO.ConventionOperAmount)
            FROM Un_ConventionOper CO
            JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND CO.ConventionOperTypeID = 'FDI'
            GROUP BY CO.ConventionID
            ) CF ON CF.ConventionID = C.ConventionID
        LEFT JOIN Un_Plan PC ON PC.PlanID = C.PlanID
        LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
        LEFT JOIN Un_Modal M ON M.ModalID = U.ModalID
        LEFT JOIN Un_Plan P ON P.PlanID = M.PlanID
        LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
        LEFT JOIN dbo.Mo_Human SH ON SH.HumanID = S.SubscriberID
        LEFT JOIN ( -- point#729                                                                                       
            SELECT 
                V1.SubscriberID, 
                TotalCapitalInsured = SubscribAmount - ISNULL(AmountToDate,0)
            FROM (-- Retourne le total des montants versés par souscripteur
                SELECT 
                    C.SubscriberID, 
                    SubscribAmount = SUM(ROUND(M.PmtRate * U.UnitQty, 2) * PmtQty)
                FROM dbo.Un_Convention C                      
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                    AND U.WantSubscriberInsurance <> 0              
                    AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID 
                ) V1
            LEFT JOIN (-- Retourne les cotisations versées jusqu'à présent par souscripteurs
                SELECT 
                    C.SubscriberID, 
                    AmountToDate = SUM(Co.Cotisation + Co.Fee)
                FROM dbo.Un_Convention C                      
                JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
                JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                    AND U.WantSubscriberInsurance <> 0
                    AND M.SubscriberInsuranceRate > 0
                GROUP BY C.SubscriberID
                ) V2 ON V1.SubscriberID = V2.SubscriberID
            ) TC ON TC.SubscriberID = S.SubscriberID
        LEFT JOIN dbo.Mo_Adr SA ON SA.AdrID = SH.AdrID
        --LEFT JOIN dbo.Mo_Human R ON R.HumanID = S.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep R_Rep ON R_Rep.RepID = S.RepID
        LEFT JOIN dbo.Mo_Human R ON R.HumanID = R_Rep.RepID
        --LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = U.RepID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep UR_Rep ON UR_Rep.RepID = U.RepID
        LEFT JOIN dbo.Mo_Human UR ON UR.HumanID = UR_Rep.RepID
        --LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = U.RepResponsableID   Remplacée par les deux lignes ci-dessous pour ajouter la table Un_Rep et obtenir la date de fin pour inscrire Inactif dans le prénom
        LEFT JOIN Un_Rep URR_Rep ON URR_Rep.RepID = U.RepResponsableID
        LEFT JOIN dbo.Mo_Human URR ON URR.HumanID = URR_Rep.RepID
        LEFT JOIN (-- Retourne le total des cotisations et de frais ainsi que la plus petite date d'opération par unités
            SELECT
                Ct.UnitID,
                OperDate = MIN(O.OperDate),
                FEE = SUM(Ct.Fee),
                Cotisation = SUM(Ct.Cotisation)
            FROM Un_Cotisation Ct
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN Un_Oper O ON O.OperID = Ct.OperID
            LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND(    ( O.OperTypeID = 'CPA' 
                         AND ISNULL(OBF.OperID, 0) > 0
                        )
                    OR O.OperDate < = GETDATE()
                    )
            GROUP BY Ct.UnitID
            ) Ct ON Ct.UnitID = U.UnitID
        LEFT JOIN (-- Sert à la détection d'un arrêt de paiement sur le groupe d'unité
            SELECT DISTINCT 
                H.UnitID
            FROM Un_UnitHoldPayment H
            JOIN dbo.Un_Unit U ON U.UnitID = H.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND H.StartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(H.EndDate,0) <= 0
                        OR H.EndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) UHP ON UHP.UnitID = U.UnitID                    
        LEFT JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne l'info des banques
            SELECT DISTINCT
                B.BankID,
                B.BankTransit,
                BankName = C.CompanyName,
                BT.BankTypeName,
                BT.BankTypeCode
            FROM Mo_Bank B
            JOIN Mo_Company C ON C.CompanyID = B.BankID
            JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID                
            JOIN Un_ConventionAccount CA ON CA.BankID = B.BankID
            JOIN dbo.Un_Convention Co ON CA.ConventionID = Co.ConventionID
            JOIN dbo.Un_Beneficiary Be ON Be.BeneficiaryID = Co.BeneficiaryID
            WHERE Be.iTutorID = @MatrixID
            ) BK ON BK.BankID = CA.BankID    
        LEFT JOIN Un_Program Prog ON Prog.ProgramID = B.ProgramID
        LEFT JOIN Un_College Co ON Co.CollegeID = B.CollegeID
        LEFT JOIN Mo_Company CoCo ON CoCo.CompanyID = Co.CollegeID
        LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
        LEFT JOIN Mo_State St ON St.StateID = S.StateID
        LEFT JOIN (-- Retourne les conventions en arrêt de paiement
            SELECT DISTINCT 
                B.ConventionID
            FROM Un_Breaking B
            JOIN dbo.Un_Convention C ON C.ConventionID = B.ConventionID
            WHERE C.BeneficiaryID = @MatrixID
                AND B.BreakingStartDate <= dbo.FN_CRQ_DateNoTime(GETDATE())
                AND    ( ISNULL(B.BreakingEndDate,0) <= 0
                        OR B.BreakingEndDate >= dbo.FN_CRQ_DateNoTime(GETDATE())
                        )
            ) BKG ON BKG.ConventionID = C.ConventionID
        LEFT JOIN (-- Retourne le nombre de dépôts par unité
            SELECT
                A.UnitID,
                AutomaticDepositCount = COUNT(A.AutomaticDepositID)
            FROM Un_AutomaticDeposit A
            JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND    ( dbo.FN_CRQ_DateNoTime(GETDATE()) BETWEEN A.StartDate AND A.EndDate
                         OR    ( dbo.FN_CRQ_DateNoTime(GETDATE()) >= A.StartDate 
                                AND ISNULL(A.EndDate,0) < 2
                                )
                        )
            GROUP BY A.UnitID
            ) AD ON AD.UnitID = U.UnitID
        LEFT JOIN (-- Retourne le nombre de nsf par convention    
            SELECT
                U.ConventionID,
                NbNSF = COUNT(DISTINCT O.OperID)
            FROM Mo_BankReturnLink R
            JOIN Un_Oper O ON O.OperID = R.BankReturnCodeID
            JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND R.BankReturnTypeID = '901'
            GROUP BY U.ConventionID        
            ) NSF ON NSF.ConventionID = C.ConventionID
        LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
        LEFT JOIN (-- 10.23.1 (2.2) : Retrouve l'état actuel d'une convention
            SELECT 
                T.ConventionID,
                CS.ConventionStateID,
                CS.ConventionStateName
            FROM (-- Retourne la plus grande date de début d'un état par convention
                SELECT 
                    S.ConventionID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_ConventionConventionState S
                JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                    AND S.StartDate <= GETDATE()
                GROUP BY S.ConventionID
                ) T
            JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID    AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
            JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
            ) CS ON C.ConventionID = CS.ConventionID
        LEFT JOIN (-- 10.23.1 (3.2) : Retrouve l'état actuel d'un groupe d'unités
            SELECT 
                T.UnitID,
                US.UnitStateID,
                US.UnitStateName
            FROM (-- Retourne la plus grande date de début d'un état par unité
                SELECT 
                    S.UnitID,
                    MaxDate = MAX(S.StartDate)
                FROM Un_UnitUnitState S
                JOIN dbo.Un_Unit U ON U.UnitID = S.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                    AND S.StartDate <= GETDATE()
                GROUP BY S.UnitID
                ) T
            JOIN Un_UnitUnitState UUS ON T.UnitID = UUS.UnitID AND T.MaxDate = UUS.StartDate -- Retrouve l'état correspondant à la plus grande date par unité
            JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID -- Pour retrouver la description de l'état
            ) US ON U.UnitID = US.UnitID
        LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
            SELECT
                U.ConventionID,
                MonthTheoricAmount = 
                    SUM(
                        ROUND(M.PmtRate * U.UnitQty,2) + -- Cotisation et frais
                        dbo.FN_CRQ_TaxRounding
                            ((    CASE U.WantSubscriberInsurance -- Assurance souscripteur
                                    WHEN 0 THEN 0
                                ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
                                END +
                                ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
                            (1+ISNULL(St.StateTaxPct,0)))) -- Taxes
            FROM dbo.Un_Unit U
            JOIN Un_Modal M ON U.ModalID = M.ModalID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            LEFT JOIN Mo_State St ON St.StateID = S.StateID
            LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
            LEFT JOIN (
                SELECT
                    U.UnitID,
                    CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
                FROM dbo.Un_Unit U
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                GROUP BY U.UnitID
                ) Ct ON U.UnitID = Ct.UnitID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
                AND M.PmtByYearID = 12
                AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
            GROUP BY U.ConventionID
            ) AMT ON C.ConventionID = AMT.ConventionID 
        LEFT JOIN CRQ_WorldLang W ON S.BirthLangID = W.WorldLanguageCodeID
        LEFT JOIN (
            SELECT
                M.UnitID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    U.UnitID,
                    U.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Unit U
                JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
                JOIN Un_RepBossHist RBH ON (RBH.RepID = U.RepID) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
                JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
                JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                GROUP BY U.UnitID, U.RepID
                ) M
            JOIN dbo.Un_Unit U ON (U.UnitID = M.UnitID)
            JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
            JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
            GROUP BY M.UnitID
            ) UDIR ON (UDIR.UnitID = U.UnitID)
        LEFT JOIN dbo.Mo_Human HUDIR ON (HUDIR.HumanID = UDIR.BossID)
        LEFT JOIN (
            SELECT
                M.SubscriberID,
                BossID = MAX(RBH.BossID)
            FROM (
                SELECT
                    S.SubscriberID,
                    S.RepID,
                    RepBossPct = MAX(RBH.RepBossPct)
                FROM dbo.Un_Subscriber S
                JOIN dbo.Un_Convention C ON (C.SubscriberID = S.SubscriberID)
                JOIN Un_RepBossHist RBH ON (RBH.RepID = S.RepID) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
                JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
                JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
                --JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                GROUP BY S.SubscriberID, S.RepID
                ) M
            JOIN dbo.Un_Subscriber S ON (S.SubscriberID = M.SubscriberID)
            JOIN dbo.Un_Convention C ON (C.SubscriberID = S.SubscriberID)
            JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
            GROUP BY M.SubscriberID
            ) SDIR ON (SDIR.SubscriberID = S.SubscriberID)
        LEFT JOIN dbo.Mo_Human HSDIR ON (HSDIR.HumanID = SDIR.BossID)
        LEFT JOIN (
            SELECT 
                CE.ConventionID,
                fCESG = SUM(CE.fCESG),
                fACESG = SUM(CE.fACESG),
                fCLB = SUM(CE.fCLB)
            FROM Un_CESP CE
            JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
            WHERE B.iTutorID = @MatrixID
                AND B.bTutorIsSubscriber = 0
            GROUP BY CE.ConventionID
            ) GG ON GG.ConventionID = C.ConventionID
        --LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID
        LEFT JOIN ( -- Unité résiliés
                SELECT 
                    U.ConventionID, 
                    UnitRes = SUM(UR.UnitQty)
                FROM Un_UnitReduction UR
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                GROUP BY U.ConventionID) SR ON SR.ConventionID = C.ConventionID
        LEFT JOIN ( -- Unité utilisés
                SELECT 
                    U.ConventionID, 
                    UnitUse = SUM(A.fUnitQtyUse)
                FROM Un_UnitReduction UR
                JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
                JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID        
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
                WHERE B.iTutorID = @MatrixID
                    AND B.bTutorIsSubscriber = 0
                GROUP BY U.ConventionID) SU ON SU.ConventionID = C.ConventionID
        LEFT JOIN @tUn_MaxConvDepositDateCfg MCD ON U.InForceDate BETWEEN MCD.dtStart AND MCD.dtEnd

        LEFT JOIN (SELECT iID_Convention_Source,iID_Convention_Destination = min(iID_Convention_Destination), iID_Unite_Source, TOPER.OperTypeID
                    FROM tblOPER_OperationsRIO TOPER 
                    WHERE (TOPER.bRIO_ANNULEE = 0 AND TOPER.bRIO_QUIANNULE = 0)
                    GROUP BY iID_Convention_Source, iID_Unite_Source, TOPER.OperTypeID) AS S1 ON S1.iID_Convention_Source = C.ConventionID  AND S1.iID_Unite_Source = U.UnitID                                              
        LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = S1.iID_Convention_Destination
        LEFT JOIN Mo_Country Corg ON Corg.CountryID = SH.cID_Pays_Origine --Pays d'origine
        LEFT JOIN Un_RelationshipType LC ON LC.tiRelationshipTypeID = C.tiID_Lien_CoSouscripteur
        LEFT JOIN tblCONV_PreferenceSuivi Prf ON PRF.iID_Preference_Suivi = S.iID_Preference_Suivi --Preference suivi
        LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID AND PS.DateProfilInvestisseur = (
            SELECT    
                MAX(PSM.DateProfilInvestisseur)
            FROM tblCONV_ProfilSouscripteur PSM
            WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
                AND PSM.DateProfilInvestisseur <= GETDATE()
            )
        LEFT JOIN tblGENE_PortailAuthentification PAS ON PAS.iUserId = S.SubscriberID 
        LEFT JOIN tblGENE_PortailAuthentification PAB ON PAB.iUserId = B.BeneficiaryID
        LEFT JOIN tblGENE_TypesParametre GTPB on GTPB.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE'
        LEFT JOIN tblGENE_Parametres GPB ON GTPB.iID_Type_Parametre = GPB.iID_Type_Parametre
        LEFT JOIN tblGENE_TypesParametre GTPS on GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR'
        LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
        LEFT JOIN (
            SELECT r.iID_Convention_Destination
            from tblOPER_OperationsRIO r
            WHERE r.OperTypeID IN ('RIO', 'RIM')
            AND r.bRIO_QuiAnnule = 0
            GROUP BY r.iID_Convention_Destination
                )FBU ON C.ConventionID = FBU.iID_Convention_Destination
        WHERE Tu.iTutorID = @MatrixID
        ORDER BY
            TuH.LastName,
            TuH.FirstName,
            BH.LastName,
            BH.FirstName,
            C.ConventionNo,
            SH.LastName,
            SH.FirstName
    END -- ELSE IF (@MatrixType = 'TUT')
END