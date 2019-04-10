/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_CreerLignesFichier
Nom du service        : Créer les lignes du fichier
But                 : Créer les lignes du fichier physique en cours de création dans le format des NID de RQ dans la
                      base de données.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        vcNom_Fichier                Nom du fichier physique à créer.
                        bDenominalisation            Indicateur de retrait des noms dans le fichier des transactions.
                        vcNEQ_GUI                    NEQ de GUI requis dans les fichiers de transactions.

Exemple d’appel        :    Cette procédure doit être appelée uniquement par "psIQEE_CreerFichiers".

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O

Historique des modifications:
    Date        Programmeur                 Description                                
    ----------  ------------------------    -----------------------------------------
    2009-09-10  Éric Deshaies               Création du service                            
    2011-05-07  Stéphane Barbeau            Remplacement du champ mIQEE_Rembourse par mIQEE_ImpotSpecial
    2011-05-08  Stéphane Barbeau            Ajout du champ @vcFormulairePrescrit pour conformité avec NIDs version 0.08L3
    2012-05-22  Eric Michaud                Relocaliser le code et le mettre dans psIQEE_CreerTransactions03 pour Un_RelationshipType 
    2012-08-29  Stéphane Barbeau            Curseur curTransactions: ajustement clause ORDER BY
    2012-12-21  Stéphane Barbeau            Ajout du champ  bLien_Frere_Soeur à la position 332 de la T03 exigé par les NIDs 2012-11.
    2016-02-15  Steeve Picard               Ajout du paramètre « iSequence » de la procédure « psIQEE_AjouterLigneFichier »
    2016-04-07  Steeve Picard               Ajustement des écritures des T04-03
    2017-06-08  Steeve Picard               Changement de paramètre pour le ID du fichier au lieu du nom du fichier
    2017-09-14  Steeve Picard               Modification des paramètres de «fnIQEE_FormaterChamp»
    2017-11-02  Steeve Picard               Retourne le nombre de lignes dans le fichier
    2018-01-30  Steeve Picard               Changement dans l'ordre de présenter les transactions du fichier avec optimisation
    2018-02-02  Steeve Picard               Force la date de transaction su 31 décembre de l'année fiscale pour les T06-91
    2018-02-08  Steeve Picard               Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-04-02  Steeve Picard               Modifier l'ordre «tiCode_Version» pour les annulations en 1er, suivi des initaux & finir par les reprises
    2018-05-02  Steeve Picard               L'identifiant du fiduciaire (NEQ) est maintenant traité comme un numérique par RQ
    2018-06-20  Steeve Picard               Correction pour les T04 pour le champ «mCotisations_Non_Donne_Droit_IQEE»
    2018-07-11  Steeve Picard               Changement pour les T05-01 «PAE» pour le l'IQÉÉ payé
    2018-09-24  Steeve Picard               Corriger l'ordre de séquence pour respecter l'ordre des dates dans une même convention à une même date
    2018-11-14  Steeve Picard               Correction du calcul dont des cotisations versées depuis l'IQÉÉ
    2018-12-10  Steeve Picard               Correction de la date de T06 lorsque c'est une annulation «tiCode_Version = 1»
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerLignesFichier
(
    @iID_Fichier_IQEE INT,
    @bDenominalisation BIT,
    @iNEQ_GUI INTEGER
)
AS
BEGIN
    -----------------------------------------------------------------
    -- Créer les lignes du fichier de transactions IQÉÉ selon les NID
    -----------------------------------------------------------------
    DECLARE @vcLigne VARCHAR(1000),
            @tiCode_Version TINYINT,
            @vcDenominalisation VARCHAR(11),
            @vcFormulairePrescrit VARCHAR(49),
            @nSequence INT
            
    -- Déterminer les caractères de remplacement en cas de dénominalisation
    SET @vcDenominalisation = 'Universitas'

    -- Champ formulaire prescrit dans les T02 et T06.  Référence NIDs version 0.08L3
    SET @vcFormulairePrescrit = 'Formulaire prescrit - Président-directeur général'

    IF OBJECT_ID('tempDB..#TB_Transaction') IS NOT NULL
        DROP TABLE #TB_Transaction

    CREATE TABLE #TB_Transaction (
        iID_Sequence INT IDENTITY(1, 1) NOT NULL,
        vcNo_Convention VARCHAR(15) NOT NULL,
        iID_Transaction INT NOT NULL,
        dtTransaction datetime NOT NULL,
        vcType_Transaction VARCHAR(5) NOT NULL,
        tiCode_Version TINYINT NOT NULL,
        PlanGovernmentRegNo VARCHAR(20) NOT NULL,
        cLigne VARCHAR(1000) NULL
    )

    SET @tiCode_Version = 1
    WHILE @tiCode_Version < 3
    BEGIN
        INSERT INTO #TB_Transaction (
            vcNo_Convention, iID_Transaction, dtTransaction, vcType_Transaction, tiCode_Version, PlanGovernmentRegNo
        )
        SELECT vcNo_Convention, iID_Trans, dtTrans, vcTypeTrans, tiCode_Version, PlanGovernmentRegNo
          FROM (
            SELECT X.vcNo_Convention, X.iID_Trans, X.dtTrans, X.vcTypeTrans, X.tiCode_Version, P.PlanGovernmentRegNo,
                   Sort_1 = X.siAnnee_Fiscale * CASE WHEN X.tiCode_Version = 1 THEN -1 ELSE 1 END,
                   Sort_2 = CASE WHEN X.vcTypeTrans = '06-91' THEN 9999999
                                 ELSE DATEDIFF(DAY, '2007-02-20', X.dtTrans) 
                            END * CASE WHEN X.tiCode_Version = 1 THEN -1 ELSE 1 END
              FROM (
                    SELECT vcNo_Convention, siAnnee_Fiscale, iID_Demande_IQEE AS iID_Trans, STR(siAnnee_Fiscale,4)+'-12-31' AS dtTrans, '02' AS vcTypeTrans, tiCode_Version
                      FROM dbo.tblIQEE_Demandes
                     WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                           AND iID_Ligne_Fichier IS NULL
                           AND cStatut_Reponse <> 'X'
                           AND tiCode_Version = @tiCode_Version
                    UNION ALL
                    SELECT vcNo_Convention, siAnnee_Fiscale, iID_Remplacement_Beneficiaire, dtDate_Remplacement, '03', tiCode_Version
                      FROM dbo.tblIQEE_RemplacementsBeneficiaire
                     WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                           AND iID_Ligne_Fichier IS NULL
                           AND cStatut_Reponse <> 'X'
                           AND tiCode_Version = @tiCode_Version
                    UNION ALL
                    SELECT T.vcNo_Convention, T.siAnnee_Fiscale, T.iID_Transfert, T.dtDate_Transfert, '04-' + S.cCode_Sous_Type, T.tiCode_Version
                      FROM dbo.tblIQEE_Transferts T JOIN dbo.tblIQEE_SousTypeEnregistrement S ON T.iID_Sous_Type = S.iID_Sous_Type
                     WHERE T.iID_Fichier_IQEE = @iID_Fichier_IQEE
                           AND T.iID_Ligne_Fichier IS NULL
                           AND T.cStatut_Reponse <> 'X'
                           AND T.tiCode_Version = @tiCode_Version
                    UNION ALL
                    SELECT P.vcNo_Convention, P.siAnnee_Fiscale, P.iID_Paiement_Beneficiaire, P.dtDate_Paiement, '05-' + S.cCode_Sous_Type, P.tiCode_Version
                      FROM dbo.tblIQEE_PaiementsBeneficiaires P JOIN dbo.tblIQEE_SousTypeEnregistrement S ON P.iID_Sous_Type = S.iID_Sous_Type
                     WHERE P.iID_Fichier_IQEE = @iID_Fichier_IQEE
                           AND P.iID_Ligne_Fichier IS NULL
                           AND P.cStatut_Reponse <> 'X'
                           AND P.tiCode_Version = @tiCode_Version
                    UNION ALL
                    SELECT I.vcNo_Convention, I.siAnnee_Fiscale, I.iID_Impot_Special, 
                           CASE WHEN I.tiCode_Version = 1 THEN I.dtDate_Evenement 
                                WHEN s.cCode_Sous_Type = '91' AND F.dtDate_Creation > '2018-02-02' 
                                THEN STR(I.siAnnee_Fiscale,4)+'-12-31' 
                                ELSE I.dtDate_Evenement 
                           END AS dtTrans, 
                           '06-' + S.cCode_Sous_Type, I.tiCode_Version
                      FROM dbo.tblIQEE_ImpotsSpeciaux I JOIN dbo.tblIQEE_SousTypeEnregistrement S ON I.iID_Sous_Type = S.iID_Sous_Type
                                                        JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                     WHERE I.iID_Fichier_IQEE = @iID_Fichier_IQEE
                           AND I.iID_Ligne_Fichier IS NULL
                           AND I.cStatut_Reponse <> 'X'
                           AND I.tiCode_Version = @tiCode_Version
                    ) X
                    JOIN dbo.Un_Convention C ON C.ConventionNo = X.vcNo_Convention
                    JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
          ) Y
        ORDER BY vcNo_Convention, Sort_1, Sort_2, vcTypeTrans, iID_Trans 
  
        SET @tiCode_Version = CASE @tiCode_Version WHEN 1 THEN 0 
                                                   WHEN 0 THEN 2 
                                                   WHEN 2 THEN 3
                              END
    END 
    SELECT * FROM #TB_Transaction 

    -- Création des enregistrements de demande de subvention (type 02)
    UPDATE TB SET cLigne = 
            /*001*/ LEFT(TB.vcType_Transaction, 2) +
            /*003*/ dbo.fnIQEE_FormaterChamp(D.tiCode_Version,'9',1,0)+
            /*004*/ dbo.fnIQEE_FormaterChamp(D.siAnnee_Fiscale,'9',4,0)+
            /*008*/ dbo.fnIQEE_FormaterChamp(@iNEQ_GUI,'9',10,0)+
            /*018*/ dbo.fnIQEE_FormaterChamp(D.vcNo_Convention,'X',15,NULL)+
            /*033*/ dbo.fnIQEE_FormaterChamp(TB.PlanGovernmentRegNo,'9',10,0)+    
            /*043*/ dbo.fnIQEE_FormaterChamp(D.dtDate_Debut_Convention,'D',8,NULL)+
            /*051*/ '1'+
            /*052*/ dbo.fnIQEE_FormaterChamp(D.tiNB_Annee_Quebec,'9',2,0)+    
            /*054*/ dbo.fnIQEE_FormaterChamp(D.mCotisations,'9',9,2)+
            /*063*/ dbo.fnIQEE_FormaterChamp(D.mTransfert_IN,'9',9,2)+
            /*072*/ dbo.fnIQEE_FormaterChamp(D.mTotal_Cotisations_Subventionnables,'9',9,2)+
            /*081*/ dbo.fnIQEE_FormaterChamp(D.mTotal_Cotisations,'9',9,2)+
            /*090*/ dbo.fnIQEE_FormaterChamp(D.vcNAS_Beneficiaire,'9',9,0)+
            /*099*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcNom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*119*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcPrenom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*139*/ dbo.fnIQEE_FormaterChamp(D.dtDate_Naissance_Beneficiaire,'D',8,NULL)+
            /*147*/ dbo.fnIQEE_FormaterChamp(D.tiSexe_Beneficiaire,'9',1,NULL)+
            /*148*/ dbo.fnIQEE_FormaterChamp(D.vcAppartement_Beneficiaire,'X',6,NULL)+
            /*154*/ dbo.fnIQEE_FormaterChamp(D.vcNo_Civique_Beneficiaire,'X',10,NULL)+
            /*164*/ dbo.fnIQEE_FormaterChamp(D.vcRue_Beneficiaire,'X',50,NULL)+
            /*214*/ dbo.fnIQEE_FormaterChamp(D.vcLigneAdresse2_Beneficiaire,'X',14,NULL)+
            /*228*/ dbo.fnIQEE_FormaterChamp(D.vcLigneAdresse3_Beneficiaire,'X',40,NULL)+
            /*268*/ dbo.fnIQEE_FormaterChamp(D.vcVille_Beneficiaire,'X',30,NULL)+
            /*298*/ dbo.fnIQEE_FormaterChamp(D.vcProvince_Beneficiaire,'A',2,NULL)+
            /*300*/ dbo.fnIQEE_FormaterChamp(D.vcPays_Beneficiaire,'A',3,NULL)+
            /*303*/ dbo.fnIQEE_FormaterChamp(D.vcCodePostal_Beneficiaire,'X',10,NULL)+
            /*313*/ dbo.fnIQEE_FormaterChamp(D.bResidence_Quebec,'9',1,NULL)+
            /*314*/ dbo.fnIQEE_FormaterChamp(D.tiType_Souscripteur,'9',1,NULL)+
            /*315*/ dbo.fnIQEE_FormaterChamp(D.vcNAS_Souscripteur,'9',9,0)+
            /*324*/ dbo.fnIQEE_FormaterChamp(D.vcNEQ_Souscripteur,'X',10,NULL)+
            /*334*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcNom_Souscripteur ELSE @vcDenominalisation END,'X',20,NULL)+
            /*354*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcPrenom_Souscripteur ELSE @vcDenominalisation END,'X',20,NULL)+
            /*374*/ dbo.fnIQEE_FormaterChamp(RTS.tiCode_Equivalence_IQEE,'9',1,0)+
            /*375*/ dbo.fnIQEE_FormaterChamp(D.vcAppartement_Souscripteur,'X',6,NULL)+
            /*381*/ dbo.fnIQEE_FormaterChamp(D.vcNo_Civique_Souscripteur,'X',10,NULL)+
            /*391*/ dbo.fnIQEE_FormaterChamp(D.vcRue_Souscripteur,'X',50,NULL)+
            /*441*/ dbo.fnIQEE_FormaterChamp(D.vcLigneAdresse2_Souscripteur,'X',14,NULL)+
            /*455*/ dbo.fnIQEE_FormaterChamp(D.vcLigneAdresse3_Souscripteur,'X',40,NULL)+
            /*495*/ dbo.fnIQEE_FormaterChamp(D.vcVille_Souscripteur,'X',30,NULL)+
            /*525*/ dbo.fnIQEE_FormaterChamp(D.vcProvince_Souscripteur,'A',2,NULL)+
            /*527*/ dbo.fnIQEE_FormaterChamp(D.vcPays_Souscripteur,'A',3,NULL)+
            /*530*/ dbo.fnIQEE_FormaterChamp(D.vcCodePostal_Souscripteur,'X',10,NULL)+
            /*540*/ dbo.fnIQEE_FormaterChamp(D.vcTelephone_Souscripteur,'9',10,0)+
            /*550*/ dbo.fnIQEE_FormaterChamp(D.vcNAS_Cosouscripteur,'9',9,0)+
            /*559*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcNom_Cosouscripteur ELSE @vcDenominalisation END,'X',20,NULL)+
            /*579*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcPrenom_Cosouscripteur ELSE @vcDenominalisation END,'X',20,NULL)+
            /*599*/ dbo.fnIQEE_FormaterChamp(RTC.tiCode_Equivalence_IQEE,'9',1,0)+
            /*600*/ dbo.fnIQEE_FormaterChamp(D.vcTelephone_Cosouscripteur,'9',10,0)+
            /*610*/ dbo.fnIQEE_FormaterChamp(D.tiType_Responsable,'9',1,NULL)+
            /*611*/ dbo.fnIQEE_FormaterChamp(D.vcNAS_Responsable,'9',9,0)+
            /*620*/ dbo.fnIQEE_FormaterChamp(D.vcNEQ_Responsable,'X',10,NULL)+
            /*630*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcNom_Responsable ELSE @vcDenominalisation END,'X',20,NULL)+
            /*650*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN D.vcPrenom_Responsable ELSE @vcDenominalisation END,'X',20,NULL)+
            /*670*/ dbo.fnIQEE_FormaterChamp(D.tiID_Lien_Responsable,'9',1,0)+
            /*671*/ dbo.fnIQEE_FormaterChamp(D.vcAppartement_Responsable,'X',6,NULL)+
            /*677*/ dbo.fnIQEE_FormaterChamp(D.vcNo_Civique_Responsable,'X',10,NULL)+
            /*687*/ dbo.fnIQEE_FormaterChamp(D.vcRue_Responsable,'X',50,NULL)+
            /*737*/ dbo.fnIQEE_FormaterChamp(D.vcLigneAdresse2_Responsable,'X',14,NULL)+
            /*751*/ dbo.fnIQEE_FormaterChamp(D.vcLigneAdresse3_Responsable,'X',40,NULL)+
            /*791*/ dbo.fnIQEE_FormaterChamp(D.vcVille_Responsable,'X',30,NULL)+
            /*821*/ dbo.fnIQEE_FormaterChamp(D.vcProvince_Responsable,'A',2,NULL)+
            /*823*/ dbo.fnIQEE_FormaterChamp(D.vcPays_Responsable,'A',3,NULL)+
            /*826*/ dbo.fnIQEE_FormaterChamp(D.vcCodePostal_Responsable,'X',10,NULL)+
            /*836*/ dbo.fnIQEE_FormaterChamp(D.vcTelephone_Responsable,'9',10,0)+
            /*846*/ dbo.fnIQEE_FormaterChamp(D.bInd_Cession_IQEE,'9',1,0)+
            /*847*/ dbo.fnIQEE_FormaterChamp(@vcFormulairePrescrit,'X',49,NULL)
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_Demandes D ON TB.iID_Transaction = D.iID_Demande_IQEE
           JOIN dbo.Un_RelationshipType RTS ON RTS.tiRelationshipTypeID = D.tiID_Lien_Souscripteur
           LEFT JOIN dbo.Un_RelationshipType RTC ON RTC.tiRelationshipTypeID = D.tiID_Lien_Cosouscripteur
     WHERE TB.vcType_Transaction = '02'

    -- Création des enregistrements de remplacement de bénéficiaire (type 03)
    UPDATE TB SET cLigne = 
            /*001*/ LEFT(TB.vcType_Transaction, 2)+
            /*003*/ dbo.fnIQEE_FormaterChamp(RB.tiCode_Version,'9',1,0)+
            /*004*/ dbo.fnIQEE_FormaterChamp(@iNEQ_GUI,'9',10,0)+
            /*014*/ dbo.fnIQEE_FormaterChamp(RB.vcNo_Convention,'X',15,NULL)+
            /*029*/ dbo.fnIQEE_FormaterChamp(TB.PlanGovernmentRegNo,'9',10,0)+    
            /*039*/ dbo.fnIQEE_FormaterChamp(RB.dtDate_Remplacement,'D',8,NULL)+
            /*047*/ dbo.fnIQEE_FormaterChamp(RB.bInd_Remplacement_Reconnu,'9',1,0)+
            /*048*/ dbo.fnIQEE_FormaterChamp(RB.vcNAS_Ancien_Beneficiaire,'9',9,0)+
            /*057*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN RB.vcNom_Ancien_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*077*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN RB.vcPrenom_Ancien_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*097*/ dbo.fnIQEE_FormaterChamp(RB.dtDate_Naissance_Ancien_Beneficiaire,'D',8,NULL)+
            /*105*/ dbo.fnIQEE_FormaterChamp(RB.tiSexe_Ancien_Beneficiaire,'9',1,0)+
            /*106*/ dbo.fnIQEE_FormaterChamp(RB.vcNAS_Nouveau_Beneficiaire,'9',9,0)+
            /*115*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN RB.vcNom_Nouveau_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*135*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN RB.vcPrenom_Nouveau_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*155*/ dbo.fnIQEE_FormaterChamp(RB.dtDate_Naissance_Nouveau_Beneficiaire,'D',8,NULL)+
            /*163*/ dbo.fnIQEE_FormaterChamp(RB.tiSexe_Nouveau_Beneficiaire,'9',1,0)+
            /*164*/ dbo.fnIQEE_FormaterChamp(RB.vcAppartement_Beneficiaire,'X',6,NULL)+
            /*170*/ dbo.fnIQEE_FormaterChamp(RB.vcNo_Civique_Beneficiaire,'X',10,NULL)+
            /*180*/ dbo.fnIQEE_FormaterChamp(RB.vcRue_Beneficiaire,'X',50,NULL)+
            /*230*/ dbo.fnIQEE_FormaterChamp(RB.vcLigneAdresse2_Beneficiaire,'X',14,NULL)+
            /*244*/ dbo.fnIQEE_FormaterChamp(RB.vcLigneAdresse3_Beneficiaire,'X',40,NULL)+
            /*284*/ dbo.fnIQEE_FormaterChamp(RB.vcVille_Beneficiaire,'X',30,NULL)+
            /*314*/ dbo.fnIQEE_FormaterChamp(RB.vcProvince_Beneficiaire,'A',2,NULL)+
            /*316*/ dbo.fnIQEE_FormaterChamp(RB.vcPays_Beneficiaire,'A',3,NULL)+                   
            /*319*/ dbo.fnIQEE_FormaterChamp(RB.vcCodePostal_Beneficiaire,'X',10,NULL)+
            /*329*/ dbo.fnIQEE_FormaterChamp(RB.tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire,'9',1,0)+
            /*330*/ dbo.fnIQEE_FormaterChamp(RB.bResidence_Quebec,'9',1,0)+
            /*331*/ dbo.fnIQEE_FormaterChamp(RB.bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial,'9',1,0)+
            /*332*/ dbo.fnIQEE_FormaterChamp(RB.bLien_Frere_Soeur,'9',1,0)
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON TB.iID_Transaction = RB.iID_Remplacement_Beneficiaire
     WHERE TB.vcType_Transaction = '03'

    -- Création des enregistrements de transfert entre régimes (type 04)
    UPDATE TB SET cLigne = 
            /*001*/ LEFT(TB.vcType_Transaction, 2)+
            /*003*/ dbo.fnIQEE_FormaterChamp(T.tiCode_Version,'9',1,0)+
            /*004*/ dbo.fnIQEE_FormaterChamp(RIGHT(TB.vcType_Transaction, 2),'X',2,NULL)+
            /*006*/ dbo.fnIQEE_FormaterChamp(@iNEQ_GUI,'9',10,0)+
            /*016*/ dbo.fnIQEE_FormaterChamp(T.vcNo_Convention,'X',15,NULL)+
            /*031*/ dbo.fnIQEE_FormaterChamp(TB.PlanGovernmentRegNo,'9',10,0)+    
            /*041*/ dbo.fnIQEE_FormaterChamp(T.dtDate_Debut_Convention,'D',8,NULL)+
            /*049*/ dbo.fnIQEE_FormaterChamp(T.dtDate_Transfert,'D',8,NULL)+
            /*057*/ dbo.fnIQEE_FormaterChamp(T.mTotal_Transfert,'9',9,2)+
            /*066*/ dbo.fnIQEE_FormaterChamp(T.mCotisations_Donne_Droit_IQEE,'9',9,2)+
            /*075*/ dbo.fnIQEE_FormaterChamp(T.mCotisations_Non_Donne_Droit_IQEE,'9',9,2)+
            /*084*/ dbo.fnIQEE_FormaterChamp(T.mIQEE_CreditBase_Transfere + T.mIQEE_Majore_Transfere,'9',9,2)+
            /*093*/ dbo.fnIQEE_FormaterChamp(T.ID_Autre_Promoteur,'X',10,NULL)+
            /*103*/ dbo.fnIQEE_FormaterChamp(T.vcNo_Contrat_Autre_Promoteur,'X',15,NULL)+
            /*118*/ dbo.fnIQEE_FormaterChamp(T.ID_Regime_Autre_Promoteur,'9',10,0)+    
            /*128*/ dbo.fnIQEE_FormaterChamp(T.vcNAS_Beneficiaire,'9',9,0)+
            /*137*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN T.vcNom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*157*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN T.vcPrenom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*177*/ dbo.fnIQEE_FormaterChamp(T.dtDate_Naissance_Beneficiaire,'D',8,NULL)+
            /*185*/ dbo.fnIQEE_FormaterChamp(T.tiSexe_Beneficiaire,'9',1,0)+
            /*186*/ dbo.fnIQEE_FormaterChamp(T.vcAppartement_Beneficiaire,'X',6,NULL)+
            /*192*/ dbo.fnIQEE_FormaterChamp(T.vcNo_Civique_Beneficiaire,'X',10,NULL)+
            /*202*/ dbo.fnIQEE_FormaterChamp(T.vcRue_Beneficiaire,'X',50,NULL)+
            /*252*/ dbo.fnIQEE_FormaterChamp(T.vcLigneAdresse2_Beneficiaire,'X',14,NULL)+
            /*266*/ dbo.fnIQEE_FormaterChamp(T.vcLigneAdresse3_Beneficiaire,'X',40,NULL)+
            /*306*/ dbo.fnIQEE_FormaterChamp(T.vcVille_Beneficiaire,'X',30,NULL)+
            /*336*/ dbo.fnIQEE_FormaterChamp(T.vcProvince_Beneficiaire,'A',2,NULL)+
            /*338*/ dbo.fnIQEE_FormaterChamp(T.vcPays_Beneficiaire,'X',3,NULL)+
            /*341*/ dbo.fnIQEE_FormaterChamp(T.vcCodePostal_Beneficiaire,'X',10,NULL)+
            /*351*/ dbo.fnIQEE_FormaterChamp(T.bTransfert_Total,'9',1,0)+
            /*352*/ dbo.fnIQEE_FormaterChamp(T.bPRA_Deja_Verse,'9',1,0)+
            /*353*/ dbo.fnIQEE_FormaterChamp(T.mJuste_Valeur_Marchande,'9',9,2)+
            /*362*/ dbo.fnIQEE_FormaterChamp(T.mBEC,'9',9,2)+
            /*371*/ dbo.fnIQEE_FormaterChamp(T.bTransfert_Autorise,'9',1,0)+
            /*372*/ dbo.fnIQEE_FormaterChamp(T.tiType_Souscripteur,'9',1,0)+
            /*373*/ dbo.fnIQEE_FormaterChamp(T.vcNAS_Souscripteur,'9',9,0)+
            /*382*/ dbo.fnIQEE_FormaterChamp(T.vcNEQ_Souscripteur,'X',10,NULL)+
            /*392*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN T.vcNom_Souscripteur ELSE @vcDenominalisation END,'X',20,NULL)+
            /*412*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN T.vcPrenom_Souscripteur ELSE @vcDenominalisation END,'X',20,NULL)+
            /*432*/ dbo.fnIQEE_FormaterChamp(RTS.tiCode_Equivalence_IQEE,'9',1,0)+
            /*433*/ dbo.fnIQEE_FormaterChamp(T.vcAppartement_Souscripteur,'X',6,NULL)+
            /*439*/ dbo.fnIQEE_FormaterChamp(T.vcNo_Civique_Souscripteur,'X',10,NULL)+
            /*449*/ dbo.fnIQEE_FormaterChamp(T.vcRue_Souscripteur,'X',50,NULL)+
            /*499*/ dbo.fnIQEE_FormaterChamp(T.vcLigneAdresse2_Souscripteur,'X',14,NULL)+
            /*513*/ dbo.fnIQEE_FormaterChamp(T.vcLigneAdresse3_Souscripteur,'X',40,NULL)+
            /*553*/ dbo.fnIQEE_FormaterChamp(T.vcVille_Souscripteur,'X',30,NULL)+
            /*583*/ dbo.fnIQEE_FormaterChamp(T.vcProvince_Souscripteur,'A',2,NULL)+
            /*585*/ dbo.fnIQEE_FormaterChamp(T.vcPays_Souscripteur,'X',3,NULL)+                   
            /*588*/ dbo.fnIQEE_FormaterChamp(T.vcCodePostal_Souscripteur,'X',10,NULL)+
            /*598*/ space(10)+    --[dbo].[fnIQEE_FormaterChamp](T.vcTelephone_Souscripteur,'9',10,0)+
            /*608*/ space(9)+    --[dbo].[fnIQEE_FormaterChamp](T.vcNAS_Cosouscripteur,'9',9,0)+
            /*617*/ space(20)+    --[dbo].[fnIQEE_FormaterChamp](CASE WHEN @bDenominalisation = 0 THEN T.vcNom_Cosouscripteur
                                --                                     ELSE @vcDenominalisation END,'X',20,NULL)+
            /*637*/ space(20)+    --[dbo].[fnIQEE_FormaterChamp](CASE WHEN @bDenominalisation = 0 THEN T.vcPrenom_Cosouscripteur
                                --                                     ELSE @vcDenominalisation END,'X',20,NULL)+
            /*657*/ space(1)+    --[dbo].[fnIQEE_FormaterChamp](RTC.tiCode_Equivalence_IQEE,'9',1,0)+
            /*658*/ space(10)+    --[dbo].[fnIQEE_FormaterChamp](T.vcTelephone_Cosouscripteur,'9',10,0)
            /*668*/ dbo.fnIQEE_FormaterChamp(T.mCotisations_Versees_Avant_Debut_IQEE,'9',9,2)+
            /*677*/ dbo.fnIQEE_FormaterChamp(T.mCotisations_Non_Donne_Droit_IQEE - T.mCotisations_Versees_Avant_Debut_IQEE,'9',9,2)
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_Transferts T ON TB.iID_Transaction = T.iID_Transfert
           LEFT JOIN dbo.Un_RelationshipType RTS ON RTS.tiRelationshipTypeID = T.tiID_Lien_Souscripteur
           LEFT JOIN dbo.Un_RelationshipType RTC ON RTC.tiRelationshipTypeID = T.tiID_Lien_Cosouscripteur
     WHERE TB.vcType_Transaction LIKE '04%'

    -- Création des enregistrements de paiement au bénéficiaire (type 05)
    UPDATE TB SET cLigne = 
            /*001*/ LEFT(TB.vcType_Transaction, 2)+
            /*003*/ dbo.fnIQEE_FormaterChamp(PB.tiCode_Version,'9',1,0)+
            /*004*/ dbo.fnIQEE_FormaterChamp(RIGHT(TB.vcType_Transaction, 2),'X',2,NULL)+
            /*006*/ dbo.fnIQEE_FormaterChamp(@iNEQ_GUI,'9',10,0)+
            /*016*/ dbo.fnIQEE_FormaterChamp(PB.vcNo_Convention,'X',15,NULL)+
            /*031*/ dbo.fnIQEE_FormaterChamp(TB.PlanGovernmentRegNo,'9',10,0)+    
            /*041*/ dbo.fnIQEE_FormaterChamp(PB.dtDate_Paiement,'D',8,NULL)+
            /*049*/ dbo.fnIQEE_FormaterChamp(PB.bRevenus_Accumules,'9',1,0)+
            /*050*/ dbo.fnIQEE_FormaterChamp(PB.mCotisations_Retirees,'9',9,2)+
            /*059*/ dbo.fnIQEE_FormaterChamp(PB.mIQEE_CreditBase + pb.mIQEE_Majoration,'9',9,2)+
            /*068*/ dbo.fnIQEE_FormaterChamp(PB.mPAE_Verse,'9',9,2)+
            /*077*/ dbo.fnIQEE_FormaterChamp(PB.mSolde_IQEE,'9',9,2)+
            /*086*/ dbo.fnIQEE_FormaterChamp(PB.mJuste_Valeur_Marchande,'9',9,2)+
            /*095*/ dbo.fnIQEE_FormaterChamp(PB.mCotisations_Versees,'9',9,2)+
            /*104*/ dbo.fnIQEE_FormaterChamp(PB.mBEC_Autres_Beneficiaires,'9',9,2)+
            /*113*/ dbo.fnIQEE_FormaterChamp(PB.mBEC_Beneficiaire,'9',9,2)+
            /*122*/ dbo.fnIQEE_FormaterChamp(PB.mSolde_SCEE,'9',9,2)+
            /*131*/ dbo.fnIQEE_FormaterChamp(PB.mProgrammes_Autres_Provinces,'9',9,2)+
            /*140*/ dbo.fnIQEE_FormaterChamp(PB.vcNAS_Beneficiaire,'9',9,0)+
            /*149*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN PB.vcNom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*169*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN PB.vcPrenom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*189*/ dbo.fnIQEE_FormaterChamp(PB.dtDate_Naissance_Beneficiaire,'D',8,NULL)+
            /*197*/ dbo.fnIQEE_FormaterChamp(PB.tiSexe_Beneficiaire,'9',1,0)+
            /*198*/ dbo.fnIQEE_FormaterChamp(PB.bResidence_Quebec,'9',1,0)+
            /*199*/ dbo.fnIQEE_FormaterChamp(PB.tiType_Etudes,'9',1,0)+
            /*200*/ dbo.fnIQEE_FormaterChamp(PB.tiDuree_Programme,'9',1,0)+
            /*201*/ dbo.fnIQEE_FormaterChamp(PB.tiAnnee_Programme,'9',1,0)+
            /*202*/ dbo.fnIQEE_FormaterChamp(PB.dtDate_Debut_Annee_Scolaire,'D',8,NULL)+
            /*210*/ dbo.fnIQEE_FormaterChamp(PB.tiDuree_Annee_Scolaire,'9',2,0)+
            /*212*/ dbo.fnIQEE_FormaterChamp(PB.vcCode_Postal_Etablissement,'X',10,NULL)+
            /*222*/ dbo.fnIQEE_FormaterChamp(PB.vcNom_Etablissement,'X',150,NULL)
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON TB.iID_Transaction = PB.iID_Paiement_Beneficiaire
     WHERE TB.vcType_Transaction LIKE '05%'

    -- Création des enregistrements d'impôts spéciaux (type 06)
    UPDATE TB SET cLigne = 
            /*001*/ LEFT(TB.vcType_Transaction, 2)+
            /*003*/ dbo.fnIQEE_FormaterChamp(TIS.tiCode_Version,'9',1,0)+
            /*004*/ dbo.fnIQEE_FormaterChamp(@iNEQ_GUI,'9',10,0)+
            /*014*/ dbo.fnIQEE_FormaterChamp(TIS.vcNo_Convention,'X',15,NULL)+
            /*029*/ dbo.fnIQEE_FormaterChamp(TB.PlanGovernmentRegNo,'9',10,0)+
            /*039*/ dbo.fnIQEE_FormaterChamp(TB.dtTransaction,'D',8,NULL)+   --TIS.dtDate_Evenement
            /*047*/ dbo.fnIQEE_FormaterChamp(TIS.mCotisations_Retirees,'9',9,2)+
            /*056*/ dbo.fnIQEE_FormaterChamp(TIS.mIQEE_ImpotSpecial,'9',9,2)+
            /*065*/ dbo.fnIQEE_FormaterChamp(TIS.mRadiation,'9',9,2)+
            /*074*/ dbo.fnIQEE_FormaterChamp(TIS.mCotisations_Donne_Droit_IQEE,'9',9,2)+
            /*083*/ dbo.fnIQEE_FormaterChamp(TIS.mJuste_Valeur_Marchande,'9',9,2)+
            /*092*/ dbo.fnIQEE_FormaterChamp(TIS.mBEC,'9',9,2)+
            /*101*/ dbo.fnIQEE_FormaterChamp(TIS.mSubvention_Canadienne,'9',9,2)+
            /*110*/ dbo.fnIQEE_FormaterChamp(TIS.mSolde_IQEE,'9',9,2)+
            /*119*/ dbo.fnIQEE_FormaterChamp(TIS.vcNAS_Beneficiaire,'9',9,0)+
            /*128*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN TIS.vcNom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*148*/ dbo.fnIQEE_FormaterChamp(CASE WHEN @bDenominalisation = 0 THEN TIS.vcPrenom_Beneficiaire ELSE @vcDenominalisation END,'X',20,NULL)+
            /*168*/ dbo.fnIQEE_FormaterChamp(TIS.dtDate_Naissance_Beneficiaire,'D',8,NULL)+
            /*176*/ dbo.fnIQEE_FormaterChamp(TIS.tiSexe_Beneficiaire,'9',1,0)+
            /*177*/ dbo.fnIQEE_FormaterChamp(RIGHT(TB.vcType_Transaction, 2),'X',2,NULL)+
            /*179*/ dbo.fnIQEE_FormaterChamp(TIS.vcCode_Postal_Etablissement,'X',10,NULL)+
            /*189*/ dbo.fnIQEE_FormaterChamp(TIS.vcNom_Etablissement,'X',150,NULL)+
            /*339*/ dbo.fnIQEE_FormaterChamp(@vcFormulairePrescrit,'X',49,NULL)
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_ImpotsSpeciaux TIS ON TB.iID_Transaction = TIS.iID_Impot_Special
     WHERE TB.vcType_Transaction LIKE '06%'

    -- Création de l'enregistrement d'entête (type 01)
    SET @nSequence = 0
    SET @vcLigne = '01'+dbo.fnIQEE_FormaterChamp(@iNEQ_GUI,'9',10,0)

    INSERT INTO dbo.tblIQEE_LignesFichier
        (iID_Fichier_IQEE, iSequence, cLigne)
    VALUES 
        (@iID_Fichier_IQEE, @nSequence, @vcLigne)

    SET @nSequence = IDENT_CURRENT('dbo.tblIQEE_LignesFichier')

    UPDATE #TB_Transaction
       SET cLigne = cLigne + dbo.fnIQEE_FormaterChamp(@nSequence + iID_Sequence,'9',15,0)

    -- Ajouter les lignes de transaction au fichier
    INSERT INTO dbo.tblIQEE_LignesFichier
        (iID_Fichier_IQEE, iSequence, cLigne)
    SELECT 
        iID_Fichier_IQEE = @iID_Fichier_IQEE, iID_Sequence, CAST(cLigne AS CHAR(1000))
    FROM
        #TB_Transaction
    ORDER BY 
        vcNo_Convention, iID_Sequence

    -- Création de l'enregistrement de fin (type 99)
    SET @nSequence = @@ROWCOUNT + 1
    SET @vcLigne = '99'+dbo.fnIQEE_FormaterChamp(@iNEQ_GUI,'9',10,0)+
                    /*   */ dbo.fnIQEE_FormaterChamp(@nSequence+1,'9',9,0)

    INSERT INTO dbo.tblIQEE_LignesFichier
        (iID_Fichier_IQEE, iSequence, cLigne)
    VALUES 
        (@iID_Fichier_IQEE, @nSequence, @vcLigne)

    -- Relie les demandes de subvention à la ligne du fichier (type 02)
    UPDATE D SET iID_Ligne_Fichier = LF.iID_Ligne_Fichier
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = TB.iID_Transaction
           JOIN dbo.tblIQEE_LignesFichier LF ON LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND LF.iSequence = TB.iID_Sequence
     WHERE TB.vcType_Transaction = '02'

    -- Relie les remplacements de bénéficiaire à la ligne du fichier (type 03)
    UPDATE RB SET iID_Ligne_Fichier = LF.iID_Ligne_Fichier
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Remplacement_Beneficiaire = TB.iID_Transaction
           JOIN dbo.tblIQEE_LignesFichier LF ON LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND LF.iSequence = TB.iID_Sequence
     WHERE TB.vcType_Transaction = '03'

    -- Relie les transferts à la ligne du fichier (type 04)
    UPDATE T SET iID_Ligne_Fichier = LF.iID_Ligne_Fichier
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_Transferts T ON T.iID_Transfert = TB.iID_Transaction
           JOIN dbo.tblIQEE_LignesFichier LF ON LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND LF.iSequence = TB.iID_Sequence
     WHERE TB.vcType_Transaction LIKE '04-%'

    -- Relie les paiement aux bénéficiaire à la ligne du fichier (type 05)
    UPDATE PB SET iID_Ligne_Fichier = LF.iID_Ligne_Fichier
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Paiement_Beneficiaire = TB.iID_Transaction
           JOIN dbo.tblIQEE_LignesFichier LF ON LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND LF.iSequence = TB.iID_Sequence
     WHERE TB.vcType_Transaction LIKE '05-%'

    -- Relie les impôts spéciaux à la ligne du fichier (type 06)
    UPDATE I SET iID_Ligne_Fichier = LF.iID_Ligne_Fichier
      FROM #TB_Transaction TB
           JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Impot_Special = TB.iID_Transaction
           JOIN dbo.tblIQEE_LignesFichier LF ON LF.iID_Fichier_IQEE = @iID_Fichier_IQEE AND LF.iSequence = TB.iID_Sequence
     WHERE TB.vcType_Transaction LIKE '06-%'

    return @nSequence
END
