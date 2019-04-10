/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	IU_UN_ReSendCotisationCESP400 
Description 		:	Forcer l’envoi au PCEE de cotisation  
Valeurs de retour   :	@ReturnValue :
							> 0 : Réussite
							<= 0 : Échec.
								
Exemple d'appel		:   EXECUTE dbo.IU_UN_ReSendCotisationCESP400 239579,334315,334314					

Note				:	
	ADX0001362	IA	2007-05-02	Bruno Lapointe			Création
	ADX0001260	UP	2007-10-26	Bruno Lapointe			Éliminer les doublons des blobs en paramètres	
	ADX0001283	UP	2008-02-21	Bruno Lapointe			Utiliser dtRegStartDate
	ADX0001289	UP	2008-03-14	Bruno Lapointe			Problème de gestion de dtRegStartDate avec heures, minutes et/ou secondes.
					2009-11-20	Jean-François Gauthier	Validation des changements de bénéficiaires
					2010-03-03	Jean-François Gauthier	Ajout du paramètre iIDConnect nécessaire à l'appel de IU_UN_CancelCotisationCESP400
					2010-04-29	Jean-François Gauthier	Ajout du paramètre optionnel @bSansVerificationPCEE400 
					2010-04-30     Jean-François Gauthier	Modication du OR pour un AND dans la vérification de @bSansVerificationPCEE400 
					2010-11-29	Pierre Paquet			Correction: Ajust du ISNULL dans la validation de @bSansVerificationPCEE400
					2010-10-14	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
					2012-12-03	Pierre-Luc Simard		Calcul du montant du FCB avec la fnPCEE_CalculerMontant400OperationFCB
					2016-01-12	Steeve Picard			Ajout du traitement des opérations «PRA»
					2016-04-06	Steve Bélanger			Ajout des FRM
					2016-04-13	Pierre-Luc Simard		Pour les FRM on appelle la IU_UN_CESP400ForOper au lieu de la IU_UN_CESP400ForCotisation
                    2017-05-12  Pierre-Luc Simard       Pour les TIN on appelle la IU_UN_CESP400ForOper au lieu de la IU_UN_CESP400ForCotisation
                                                        si le TIN n'a pas de cotisation
					2017-11-01	Steeve Picard			Ajout du traitement des opérations «PEE»
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ReSendCotisationCESP400]
(   @ConventionID INT, -- ID de la convention
    @iCotisationBlobID INT, -- ID du blob qui contient les CotisationID des cotisations dont il faut forcer l’envoi au PCEE.
    @iOperBlobID INT, 
    @iIDConnect INT= NULL, 
    @bSansVerificationPCEE400 INT= NULL
) -- ID du blob qui contient les OperID des opérations dont il faut forcer l’envoi au PCEE. On doit y retrouver seulement les lignes pour lesquelles nous n’Avons pas de CotisationID (nulle) par exemple les PAE et les AVC.
AS
BEGIN

    DECLARE @iResult INT, 
            @CotisationID INT, 
            @OperID INT, 
            @OperTypeID CHAR(3), 
            @tiCESP400TypeID TINYINT,
            @tiCESP400WithdrawReasonID TINYINT, 
            @iCompteEnrg INT= 0;

    DECLARE @tCotToReSend TABLE (
                CotisationID INT PRIMARY KEY, 
                OperID INT NOT NULL, 
                OperTypeID CHAR(3) NOT NULL
            );
    DECLARE @tOperToReSend TABLE (
                OperID INT PRIMARY KEY, 
                OperTypeID CHAR(3) NOT NULL
            );

    -- Table des cotiations passées en paramètre dont il faut faire le renvoi
    IF @iCotisationBlobID > 0
        INSERT INTO @tCotToReSend
            SELECT DISTINCT
                   Ct.CotisationID, O.OperID, O.OperTypeID
              FROM dbo.FN_CRI_BlobToIntegerTable (@iCotisationBlobID) V -- Decode le blob en une table
                   JOIN Un_Cotisation Ct ON Ct.CotisationID = V.iVal
                   JOIN Un_Oper O ON O.OperID = Ct.OperID
                   LEFT JOIN Un_OperCancelation OC ON O.OperID IN (OC.OperID, OC.OperSourceID) -- Annulation
                   LEFT JOIN Mo_BankReturnLink L ON O.OperID IN (L.BankReturnCodeID, L.BankReturnSourceCodeID) -- NSF
                   LEFT JOIN Un_OperBankFile F ON F.OperID = O.OperID
             WHERE OC.OperID IS NULL -- Exclu les annulations et les annulées
                   AND L.BankReturnCodeID IS NULL -- Exclu les NSF et les opérations fesant l'objet de NSF
                   AND (
                        O.OperTypeID <> 'CPA' -- Exclu les CPA anticipés
                        OR F.OperID IS NOT NULL
                   );

    -- Table des opérations passées en paramètre dont il faut faire le renvoi
    IF @iOperBlobID > 0
        INSERT INTO @tOperToReSend
            SELECT DISTINCT
                   O.OperID, O.OperTypeID
              FROM dbo.FN_CRI_BlobToIntegerTable (@iOperBlobID) V -- Decode le blob en une table
                   JOIN Un_Oper O ON O.OperID = V.iVal
                   LEFT JOIN Un_OperCancelation OC ON O.OperID IN (OC.OperID, OC.OperSourceID) -- Annulation
                   LEFT JOIN Mo_BankReturnLink L ON O.OperID IN (L.BankReturnCodeID, L.BankReturnSourceCodeID) -- NSF
                   LEFT JOIN Un_OperBankFile F ON F.OperID = O.OperID
             WHERE OC.OperID IS NULL -- Exclu les annulations et les annulées
                   AND L.BankReturnCodeID IS NULL -- Exclu les NSF et les opérations fesant l'objet de NSF
                   AND (
                        O.OperTypeID <> 'CPA' -- Exclu les CPA anticipés
                        OR F.OperID IS NOT NULL
                   );
    
    -- 2009-11-20 : Validation des changements potentiels de bénéficiaire
    --				Il faut s'assurer que toutes les transactions dans le BLOB appartiennent aux bénéficiaires actuels,
    --				sinon, il faut les supprimer du BLOB
    -- Vérification pour les cotisations 
    -- 2010-04-29 : JFG : Ajout du IF de validation
    IF (
          (
             NOT EXISTS (
                SELECT 1		-- Vérification du droit attribué à l'usager
                  FROM dbo.Mo_Right r
                       INNER JOIN dbo.Mo_UserRight ur ON r.RightID = ur.RightID
                       INNER JOIN dbo.Mo_Connect c ON ur.UserID = c.UserID
                 WHERE r.RightCode = 'PCEE_400_AUTRE_BENEF'
                       AND c.ConnectID = ISNULL(@iIDConnect, -1)
             )
             AND NOT EXISTS (
                SELECT 1		-- Vérification du droit attribué au groupe de l'usager
                 FROM dbo.Mo_Right r
                      INNER JOIN dbo.Mo_UserGroupRight ugr ON r.RightID = ugr.RightID
                      INNER JOIN dbo.Mo_UserGroupDtl ugd ON ugd.UserGroupID = ugr.UserGroupID
                      INNER JOIN dbo.Mo_Connect c ON ugd.UserID = c.UserID
                WHERE r.RightCode = 'PCEE_400_AUTRE_BENEF'
                      AND c.ConnectID = ISNULL(@iIDConnect, -1)
             )
          )
       )
       AND ISNULL(@bSansVerificationPCEE400, 0) <> 1		-- 2010-04-29 : JFG : Ajout de cette valiation
    BEGIN
        DELETE FROM @tCotToReSend
         WHERE CotisationID IN (
                    SELECT ce4.CotisationID
                      FROM @tCotToReSend t -- CotisationID
                           INNER JOIN dbo.Un_CESP400 ce4 ON t.CotisationID = ce4.CotisationID
                           INNER JOIN dbo.Un_Convention c ON ce4.ConventionID = c.ConventionID
                           INNER JOIN (
                                 SELECT ch2.iID_Convention, ch2.iID_Changement_Beneficiaire, ch2.dtDate_Changement_Beneficiaire
                                   FROM dbo.tblCONV_ChangementsBeneficiaire ch2
                                        INNER JOIN (
                                              SELECT tmp.iID_Convention, dtDate_Changement_Beneficiaire = MAX(tmp.dtDate_Changement_Beneficiaire)
                                                FROM dbo.tblCONV_ChangementsBeneficiaire tmp
                                               GROUP BY tmp.iID_Convention
                                        ) ch1 ON ch2.iID_Convention = ch1.iID_Convention
                                                 AND ch2.dtDate_Changement_Beneficiaire = ch1.dtDate_Changement_Beneficiaire
                           ) cb ON cb.iID_Convention = c.ConventionID
                     WHERE cb.iID_Changement_Beneficiaire <> c.BeneficiaryID
                           AND ce4.dtTransaction < cb.dtDate_Changement_Beneficiaire
               );
        
        SET @iCompteEnrg = @@ROWCOUNT;
        
        DELETE FROM @tOperToReSend
         WHERE OperID IN (
                    SELECT ce4.OperID
                      FROM @tOperToReSend t -- OperID
                           INNER JOIN dbo.Un_CESP400 ce4 ON t.OperID = ce4.OperID
                           INNER JOIN dbo.Un_Convention c ON ce4.ConventionID = c.ConventionID
                           INNER JOIN (
                                 SELECT ch2.iID_Convention, ch2.iID_Changement_Beneficiaire, ch2.dtDate_Changement_Beneficiaire
                                   FROM dbo.tblCONV_ChangementsBeneficiaire ch2
                                        INNER JOIN (
                                              SELECT tmp.iID_Convention, dtDate_Changement_Beneficiaire = MAX(tmp.dtDate_Changement_Beneficiaire)
                                                FROM dbo.tblCONV_ChangementsBeneficiaire tmp
                                               GROUP BY tmp.iID_Convention
                                        ) ch1 ON ch2.iID_Convention = ch1.iID_Convention
                                                 AND ch2.dtDate_Changement_Beneficiaire = ch1.dtDate_Changement_Beneficiaire
                           ) cb ON cb.iID_Convention = c.ConventionID
                     WHERE cb.iID_Changement_Beneficiaire <> c.BeneficiaryID
                           AND ce4.dtTransaction < cb.dtDate_Changement_Beneficiaire
               );

        SET @iCompteEnrg = @iCompteEnrg + @@ROWCOUNT;

        -- 2009-11-20 : Retour du nombre de transactions non traitées (supprimées des tables temporaires)
        IF @iCompteEnrg > 0
           SET @iResult = @iCompteEnrg;
    END;

    -----------------
    BEGIN TRANSACTION;
    -----------------
    -- Annule toutes les enregistrements 400 valides qui était sur les cotisations ou 
    -- opérations avant leurs renvoi
    -- 2010-04-29 : JFG : Ajout du paramètre @bSansVerificationPCEE400
    EXECUTE @iResult = IU_UN_CancelCotisationCESP400 @iCotisationBlobID, @iOperBlobID, 1, @iIDConnect, @bSansVerificationPCEE400;
    IF @iResult > 0 AND @iCotisationBlobID > 0
    BEGIN
        -- Type 11 - Différent de FCB
        INSERT INTO Un_CESP400 (
            OperID, CotisationID, ConventionID, tiCESP400TypeID, vcTransID, 
            dtTransaction, iPlanGovRegNumber, ConventionNo, vcSubscriberSINorEN, vcBeneficiarySIN, 
            fCotisation, bCESPDemand, fCESG, fACESGPart, fEAPCESG, 
            fEAP, fPSECotisation, vcPCGSINorEN, vcPCGFirstName, vcPCGLastName, 
            tiPCGType, fCLB, fEAPCLB, fPG, fEAPPG
        )
        SELECT Ct.OperID, Ct.CotisationID, C.ConventionID, 11, 'FIN', 
               Ct.EffectDate, P.PlanGovernmentRegNo, C.ConventionNo, HS.SocialNumber, HB.SocialNumber, 
               Ct.Cotisation + Ct.Fee, C.bCESGRequested, 0, 0, 0, 
               0, 0, CASE WHEN C.bACESGRequested = 0 THEN NULL
                          ELSE B.vcPCGSINOrEN
                     END,
                     CASE WHEN C.bACESGRequested = 0 THEN NULL
                          ELSE B.vcPCGFirstName
                     END,
                    CASE
                        WHEN C.bACESGRequested = 0
                        THEN NULL
                        ELSE B.vcPCGLastName
                    END,
               B.tiPCGType, 0, 0, 0, 0
          FROM @tCotToReSend V
               JOIN Un_Cotisation Ct ON V.CotisationID = Ct.CotisationID
               JOIN Un_Oper O ON O.OperID = Ct.OperID
               JOIN Un_OperType OT ON O.OperTypeID = OT.OperTypeID
               JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
               JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
               JOIN Un_Plan P ON P.PlanID = C.PlanID
               JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
               JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
               JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
               LEFT JOIN Un_TFR T ON T.OperID = O.OperID
               LEFT JOIN (
                    SELECT U.ConventionID, FCBOperID = MAX(O.OperID)
                      FROM dbo.Un_Unit U
                           JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
                           JOIN Un_Oper O ON O.OperID = Ct.OperID
                     WHERE U.ConventionID = @ConventionID -- Convention passée en paramètre seulement
                           AND O.OperTypeID = 'FCB' -- Opération FCB
                           -- Ne tient pas compte des FCB annulés ni des FCB d'annulation.
                           AND O.OperID NOT IN (
                                    SELECT OperID FROM Un_OperCancelation
                                    UNION
                                    SELECT OperSourceID FROM Un_OperCancelation
                               )
                     GROUP BY U.ConventionID
               ) FCB ON FCB.ConventionID = C.ConventionID
         -- Pas dans un compte bloqué
         WHERE C.dtRegStartDate IS NOT NULL
               AND O.OperTypeID <> 'FCB'
               AND (
                    Ct.EffectDate > dbo.FN_CRQ_DateNoTime(C.dtRegStartDate)
                    OR (
                        Ct.EffectDate = dbo.FN_CRQ_DateNoTime(C.dtRegStartDate)
                        AND Ct.OperID >= ISNULL(FCB.FCBOperID, Ct.OperID - 1)
                       )
                   )
               AND OT.GovernmentTransTypeID = 11
               AND (
                    O.OperTypeID <> 'TFR' -- Si c'est un TFR il doit être marqué à envoyer au PCEE
                    OR ISNULL(T.bSendToPCEE, 0) = 1
                   );
					
        -- Type 11 - FCB
        INSERT INTO Un_CESP400 (
            OperID, CotisationID, ConventionID, tiCESP400TypeID, vcTransID, 
            dtTransaction, iPlanGovRegNumber, ConventionNo, vcSubscriberSINorEN, vcBeneficiarySIN, 
            fCotisation, bCESPDemand, fCESG, fACESGPart, fEAPCESG, 
            fEAP, fPSECotisation, vcPCGSINorEN, vcPCGFirstName, vcPCGLastName, 
            tiPCGType, fCLB, fEAPCLB, fPG, fEAPPG
        )
        SELECT Ct.OperID, Ct.CotisationID, C.ConventionID, 11, 'FIN', 
               Ct.EffectDate, P.PlanGovernmentRegNo, C.ConventionNo, HS.SocialNumber, HB.SocialNumber, 
               fCotisation = dbo.fnPCEE_CalculerMontant400OperationFCB(Ct.OperID), -- Calcule le montant du FCB à déclarer au PCEE
                   C.bCESGRequested, 0, 0, 0, 
               0, 0, CASE WHEN C.bACESGRequested = 0 THEN NULL
                          ELSE B.vcPCGSINOrEN
                     END,
                     CASE WHEN C.bACESGRequested = 0 THEN NULL
                          ELSE B.vcPCGFirstName
                     END,
                    CASE
                        WHEN C.bACESGRequested = 0
                        THEN NULL
                        ELSE B.vcPCGLastName
                    END,
               B.tiPCGType, 0, 0, 0, 0
          FROM @tCotToReSend V
               JOIN Un_Cotisation Ct ON V.CotisationID = Ct.CotisationID
               JOIN Un_Oper O ON O.OperID = Ct.OperID
               JOIN Un_OperType OT ON O.OperTypeID = OT.OperTypeID
               JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
               JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
               JOIN Un_Plan P ON P.PlanID = C.PlanID
               JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
               JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
               JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
         WHERE C.dtRegStartDate IS NOT NULL
               AND O.OperTypeID = 'FCB';

        IF @@ERROR <> 0
            SET @iResult = -1;
    END;
	-- Gére les transactions de type différent de 11 (-1, 13, 14, 19, 21-(1,2,3,4,9,10), 23)
    DECLARE crCotToReSend CURSOR
        FOR SELECT Ct.CotisationID, Ct.OperID, OT.OperTypeID
              FROM @tCotToReSend V
                   JOIN Un_Cotisation Ct ON V.CotisationID = Ct.CotisationID
                   JOIN Un_Oper O ON O.OperID = Ct.OperID
                   JOIN Un_OperType OT ON O.OperTypeID = OT.OperTypeID
             WHERE OT.GovernmentTransTypeID <> 11;

    OPEN crCotToReSend;
    FETCH NEXT FROM crCotToReSend INTO @CotisationID, @OperID, @OperTypeID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @OperTypeID = 'AJU'
        BEGIN
            IF EXISTS ( -- Vérifie s'il s'agit d'une cotisation augmentant le solde des épargnes et frais
                    SELECT *
                    FROM Un_Cotisation
                    WHERE CotisationID = @CotisationID
                        AND Cotisation + Fee > 0
               )
                -- Insère les enregistrements 400 de type 11 sur la cotisation
                EXECUTE @iResult = IU_UN_CESP400ForCotisation 1, @CotisationID, 11, 0;
            ELSE 
                -- Insère les enregistrements 400 de type 21-1 sur la cotisation
                EXECUTE @iResult = IU_UN_CESP400ForCotisation 1, @CotisationID, 21, 1;
        END;
        ELSE
        IF @OperTypeID = 'OUT'
        BEGIN
            IF EXISTS (
                    SELECT Ct.CotisationID
                      FROM Un_Cotisation Ct
                           JOIN Un_Oper O ON O.OperID = Ct.OperID
                           JOIN Un_OUT OUT ON OUT.OperID = Ct.OperID
                     WHERE Ct.CotisationID = @CotisationID
                           -- Le promoteur n'a pas signé d'entente avec le RHDCC
                           AND (
                                OUT.bEligibleForCESG = 0
                                -- Le régime cessionnaire comporte plusieurs bénéficiaires qui ne sont pas tous frères et soeurs
                                OR OUT.bOtherContratBnfAreBrothers = 0
                               )
               )
               AND EXISTS (
                    SELECT C4.ConventionID
                      FROM Un_Cotisation Ct
                           JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
                           JOIN Un_CESP400 C4 ON C4.ConventionID = U.ConventionID
                           JOIN Un_CESP CE ON CE.OperID = C4.OperID
                     WHERE Ct.CotisationID = @CotisationID
                           -- SCEE+ envoyé PAE pour la convention(sur ce groupe d'unités)
                           AND C4.tiCESP400TypeID = 13
                           AND CE.fACESG <> 0
               )
            BEGIN
                -- Enregistrement 400 de type 21-4 Avec remboursement au prorata de la SCEE et SCEE+
                EXECUTE @iResult = IU_UN_CESP400ForOper 1, @OperID, 21, 4;

                -- Insère les enregistrements 400 sur l'opération OUT	
                IF @iResult > 0
                    EXECUTE @iResult = IU_UN_CESP400ForOper 1, @OperID, 23, 0;
            END
        END;
        ELSE
        IF @OperTypeID = 'RES'
        BEGIN
            -- Vérifie s'il s'agit d'une résiliations totales
            IF NOT EXISTS ( -- Vérifie si tous les unités de la convention sont résiliés
                    SELECT U.ConventionID
                      FROM Un_Cotisation Ct
                           JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
                           JOIN dbo.Un_Unit UC ON UC.ConventionID = U.ConventionID
                     WHERE Ct.CotisationID = @CotisationID
                     GROUP BY U.ConventionID
                    HAVING SUM(UC.UnitQty) = 0
               )
               OR EXISTS ( -- Vérifie que c'est la dernière opération de type RES de la convention.
                    SELECT Ct.OperID
                      FROM Un_Cotisation Ct
                           JOIN Un_Oper O ON O.OperID = Ct.OperID
                           JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
                           JOIN dbo.Un_Unit UC ON UC.ConventionID = U.ConventionID
                           JOIN Un_Cotisation Ct2 ON Ct2.UnitID = UC.UnitID
                           JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
                                              AND O2.OperTypeID = 'RES'
                                              AND O2.OperDate > O.OperDate
                     WHERE Ct.CotisationID = @CotisationID
               )
                -- Résiliation partielles - Insère les enregistrements 400 de type 21-1 sur l'opération
                EXECUTE @iResult = IU_UN_CESP400ForOper 1, @OperID, 21, 1;
            ELSE
            IF @OperID > 0
                -- Résiliation totales - Insère les enregistrements 400 de type 21-3 sur l'opération
                EXECUTE @iResult = IU_UN_CESP400ForOper 1, @OperID, 21, 3;
        END;
        ELSE
        IF @OperTypeID = 'RET'
        BEGIN
            -- Va chercher la raison de retrait
            SELECT TOP 1 @tiCESP400WithdrawReasonID = tiCESP400WithdrawReasonID
              FROM Un_WithdrawalReason
             WHERE OperID = @OperID;

            -- Insère les enregistrements 400 de type 21
            EXECUTE @iResult = IU_UN_CESP400ForCotisation 1, @CotisationID, 21, @tiCESP400WithdrawReasonID;
        END;
        ELSE
        IF @OperTypeID = 'RIN'
        BEGIN
            IF EXISTS (
                SELECT *
                  FROM Un_IntReimbOper O
                       JOIN Un_IntReimb I ON I.IntReimbID = O.IntReimbID
                 WHERE O.OperID = @OperID
                       AND CESGRenonciation = 1
            )
                -- Renonce à la subvention : Retrait - Insère les enregistrements 400 de type 21 sur l'opération
                EXECUTE @iResult = IU_UN_CESP400ForOper 1, @OperID, 21, 1;
            ELSE
                -- Garde la subvention : Retrait EPS - Insère les enregistrements 400 de type 14 sur l'opération
                EXECUTE @iResult = IU_UN_CESP400ForOper 1, @OperID, 14, 0;
        END;
        ELSE
        IF @OperTypeID = 'TIN'
        BEGIN
            -- Insère les enregistrements 400 de type 19 sur la cotisation
            EXECUTE @iResult = IU_UN_CESP400ForCotisation 1, @CotisationID, 19, 0;
            

        END;
        ELSE
        IF @OperTypeID = 'TRA'
        BEGIN
            IF EXISTS ( -- Vérifie s'il s'agit d'une cotisation augmentant le solde des épargnes et frais
                SELECT *
                  FROM Un_Cotisation
                 WHERE CotisationID = @CotisationID
                       AND Cotisation + Fee > 0
            )
                -- Insère les enregistrements 400 de type 11 sur la cotisation
                EXECUTE @iResult = IU_UN_CESP400ForCotisation 1, @CotisationID, 11, 0;
            ELSE 
                -- Insère les enregistrements 400 de type 21-1 sur la cotisation
                EXECUTE @iResult = IU_UN_CESP400ForCotisation 1, @CotisationID, 21, 1;
        END
		;;;;;;

        FETCH NEXT FROM crCotToReSend INTO @CotisationID, @OperID, @OperTypeID;
    END;

    CLOSE crCotToReSend;
    DEALLOCATE crCotToReSend;

    -- Gére les transactions de PAE
    DECLARE crOperToReSend CURSOR
        FOR SELECT OperID, OperTypeID
              FROM @tOperToReSend;

    OPEN crOperToReSend;
    FETCH NEXT FROM crOperToReSend INTO @OperID, @OperTypeID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @tiCESP400TypeID = 0,
               @tiCESP400WithdrawReasonID = 0

        -- Insère les enregistrements 400 de type 13 sur l'opération	
        IF @OperTypeID = 'PAE'
            SET @tiCESP400TypeID = 13

        -- Insère les enregistrements 400 de type 19 sur l'opération	
        ELSE IF @OperTypeID = 'TIN'
        BEGIN
            IF NOT EXISTS (
                SELECT *
                FROM Un_Cotisation CT
                WHERE CT.OperID = @OperID                       
            )
                SELECT @tiCESP400TypeID = 19,
                       @tiCESP400WithdrawReasonID = 0
        END 

        -- Insère les enregistrements 400 de type 21-2 sur l'opération
        ELSE IF @OperTypeID = 'PRA'
            SELECT @tiCESP400TypeID = 21,
                   @tiCESP400WithdrawReasonID = 2

		-- Insère les enregistrements 400 de type 21-3 sur l'opération FRM
		ELSE IF @OperTypeID = 'FRM'
            SELECT @tiCESP400TypeID = 21,
                   @tiCESP400WithdrawReasonID = 3

        -- Insère les enregistrements 400 de type 21-6 sur l'opération
        ELSE IF @OperTypeID = 'PEE'
            SELECT @tiCESP400TypeID = 21,
                   @tiCESP400WithdrawReasonID = 6

        IF @tiCESP400TypeID <> 0
            EXECUTE @iResult = IU_UN_CESP400ForOper 1, @OperID, @tiCESP400TypeID, @tiCESP400WithdrawReasonID;


        FETCH NEXT FROM crOperToReSend INTO @OperID, @OperTypeID;
    END;

    CLOSE crOperToReSend;
    DEALLOCATE crOperToReSend;

    IF @iResult > 0
    BEGIN
        -- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
        UPDATE Un_CESP400
           SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
         WHERE vcTransID = 'FIN';

        IF @@ERROR <> 0
            SET @iResult = -2;
    END;

    IF @iResult > 0
        ------------------
        COMMIT TRANSACTION
        ------------------
    ELSE
        --------------------
        ROLLBACK TRANSACTION;
        --------------------

    RETURN (@iResult);
END;