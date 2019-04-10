
-- =============================================
--Copyrights (c) 2008 Gestion Universitas inc
--Nom                 :	psPCEE_CreerEnregistrements511
--Description         :	Génération des enregistremsnts 511
--Valeurs de retours  :	@Return_Value :
--						> 0  :	Tout à fonctionné(nombre d'enregistrements 511 généré)
--		                < 0  :	Erreur SQL
--                      = 0  :  Aucun enregistrements 511 à été généré
--Note                :	2008-10-21	Fatiha Araar	Création
--                    : 2008-11-07  Fatiha Araar    Correction, ajouter les 511 pour les 400  
--                                                  n’ayant jamais reçu de subvention supplémentaire
--                    : 2008-11-19  Fatiha Araar    supprimer les cotisations dont la date effective est antérieure à la date de naissance du bénéficiaire
--                    : 2008-11-21  Fatiha Araar    Correction
--					  : 2009-11-26  Jean-François Gauthier Exclusion des enregistrements 400 qui ne sont pas liés au bénéficiaire actuel de la convention.
--						2010-08-16	Pierre Paquet	Utilisation du ISNULL pour détecter les champs à blanc ou à NULL.
-- =============================================
CREATE PROCEDURE dbo.psPCEE_CreerEnregistrements511 
AS
BEGIN
	DECLARE @iResult	AS INTEGER,
            @dtEnd		AS DATETIME,
            @dtBegin	AS DATETIME

    SET @iResult = 0
    SET @dtEnd = GETDATE() --Date fin
    SET @dtBegin  = DATEADD(MONTH,-36,DATEADD(DAY,-DAY(GETDATE())+8,GETDATE())) --Date début(on recule jusqu'au 8 du mois)
      --On crée une table temporaire qui contiendra les transactions 400 à corriger
      CREATE TABLE #C400 (
         iCESP400ID INT PRIMARY KEY,
	     CotisationID INT NOT NULL,
	     ConventionID INT NOT NULL,
         iCESP900ID INT NULL)
      --Ajouter les transactions 400 qui n'ont reçus aucune subvention dans la table temporaire
      --à cause d'une erreur
      INSERT INTO #C400
			   SELECT C4.iCESP400ID, C4.CotisationID, C4.ConventionID,MAX(C9.iCESP900ID)
				 FROM UN_CESP400 C4
            LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID AND R4.iCESP800ID IS NULL
            LEFT JOIN dbo.Un_Convention Co ON C4.ConventionID = Co.ConventionID
            LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
			LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
		    LEFT JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID
            LEFT JOIN (SELECT 
						C9.iCESP400ID,
						ACESG = SUM(C9.fACESG)
					     FROM Un_CESP900 C9 
					 GROUP BY C9.iCESP400ID
					) C9Sum ON C9Sum.iCESP400ID = C9.iCESP400ID
                WHERE C4.tiCESP400TypeID = 11 --Une cotisation
		          AND C4.iCESPSendFileID IS NOT NULL --Être envoyé au PCEE
		          AND C4.iCESP800ID IS NULL --Pas en erreur
		          AND C4.iReversedCESP400ID IS NULL --Pas une annulation
                  AND C4.dtTransaction BETWEEN @dtBegin AND @dtEnd ---- Seulement les transactions de la période sélectionnée
                  AND C4.OperID NOT IN(SELECT OperSourceID FROM Un_OperCancelation)--PAS annulé
                  AND Co.bACESGRequested  = 1 -- SCEE+ demandé
                  AND Co.bSendToCESP  = 1 -- doit être envoyée au PCEE
                  AND S.iCESPReceiveFileID IS NOT NULL --Avoir reçu une répance
		          AND C9.cCESP900ACESGReasonID IN ('4','H','I','J','L','M') --Causes d'annulation
                  AND R4.iCESP400ID IS NULL -- Pas annulé
                  AND C9Sum.ACESG = 0 --Pas de SCEE+ versé
                --  AND (B.vcPCGSINorEN IS NOT NULL) 
				  AND ISNULL(B.vcPCGSINorEN, '') <> ''
                --  AND (B.vcPCGLastName IS NOT NULL) 
			      AND ISNULL(B.vcPCGLastName, '') <> ''
                --  AND (B.tiPCGTYpe  IS NOT NULL)
				  AND ISNULL(B.tiPCGTYpe, '') <> ''
                --  AND (B.vcPCGFirstName IS NOT NULL OR B.tiPCGTYpe = 2)-- Les informations du pricipale responsable sont défini
				  AND (ISNULL(B.vcPCGFirstName, '') <> '' OR B.tiPCGTYpe = 2)
                  AND (C4.vcPCGSINorEN <> B.vcPCGSINorEN
                       OR C4.vcPCGLastName <> B.vcPCGLastName
                       OR C4.vcPCGFirstName <> B.vcPCGFirstName) -- Au moin l'une de ces informations à changé
             GROUP BY C4.iCESP400ID, C4.CotisationID, C4.ConventionID

   UNION ALL
      
      --Ajouter les transactions 400 qui n'ont reçus aucune subvention dans la table temporaire
      --à cause de l'abssance du principal responsable
               SELECT C4.iCESP400ID, C4.CotisationID, C4.ConventionID,MAX(C9.iCESP900ID)
				 FROM UN_CESP400 C4
            LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID AND R4.iCESP800ID IS NULL
            LEFT JOIN dbo.Un_Convention Co ON C4.ConventionID = Co.ConventionID
            LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
			LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
            LEFT JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID
            LEFT JOIN (SELECT 
						     C9.iCESP400ID,
						     ACESG = SUM(C9.fACESG)
					     FROM Un_CESP900 C9 
					 GROUP BY C9.iCESP400ID
					) C9Sum ON C9Sum.iCESP400ID = C9.iCESP400ID
		        WHERE C4.tiCESP400TypeID = 11 --Une cotisation
		          AND C4.iCESPSendFileID IS NOT NULL --Être envoyé au PCEE
		          AND C4.iCESP800ID IS NULL --Pas en erreur
		          AND C4.iReversedCESP400ID IS NULL --Pas une annulation
                  AND C4.dtTransaction BETWEEN @dtBegin AND @dtEnd ---- Seulement les transactions de la période sélectionnée
                  AND C4.OperID NOT IN(SELECT OperSourceID FROM Un_OperCancelation)--PAS annulé
                  AND Co.bACESGRequested  = 1 -- SCEE+ demandé
                  AND Co.bSendToCESP  = 1 -- doit être envoyée au PCEE
                  AND S.iCESPReceiveFileID IS NOT NULL --Avoir reçu une répance
                  AND C9.cCESP900ACESGReasonID IN ('6') --Causes d'annulation
                  AND R4.iCESP400ID IS NULL -- Pas annulé
                  AND C9Sum.ACESG = 0 --Pas de SCEE+ versé
		          --AND (B.vcPCGSINorEN IS NOT NULL) 
                  --AND (B.vcPCGLastName IS NOT NULL) 
                  --AND (B.tiPCGTYpe  IS NOT NULL)
                  --AND (B.vcPCGFirstName IS NOT NULL OR B.tiPCGTYpe = 2) -- Les informations du pricipale responsable sont défini
               	  AND ISNULL(B.vcPCGSINorEN, '') <> ''
                  AND ISNULL(B.vcPCGLastName, '') <> ''
                  AND ISNULL(B.tiPCGTYpe, '') <> ''
                  AND (ISNULL(B.vcPCGFirstName, '') <> '' OR B.tiPCGTYpe = 2)
				  --AND (C4.vcPCGSINorEN IS NULL -- Les champs du princpale reponsable sont vides ce qui indique que la SCEE+ n'était pas demandée.
                  --     OR C4.vcPCGLastName IS NULL
                  --     OR C4.vcPCGFirstName IS NULL AND B.tiPCGTYpe = 1
                  --     OR C4.tiPCGTYpe IS NULL)
				  AND (ISNULL(C4.vcPCGSINorEN, '') = ''
					   OR ISNULL(C4.vcPCGLastName, '') = ''
					   OR ISNULL(C4.vcPCGFirstName, '') = ''
					   OR ISNULL(C4.tiPCGTYpe, '') = '')
	        GROUP BY C4.iCESP400ID, C4.CotisationID, C4.ConventionID
		
      -- Exclu les cotisations dont la date effective est antérieure à la date de naissance du bénéficiaire (UP-ADX0001291).
		DELETE #C400
		FROM #C400 #C4
		JOIN dbo.Un_Convention C ON C.ConventionID = #C4.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
		JOIN Un_Cotisation Ct ON Ct.CotisationID = #C4.CotisationID
		WHERE Ct.EffectDate < H.BirthDate
	  
        -- Exclu les cotisations possédant une date de résiliation ou un transfére
		DELETE #C400
		FROM #C400 #C4
		JOIN Un_Cotisation CT ON CT.CotisationID = #C4.CotisationID
		JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
		WHERE U.TerminatedDate IS NOT NULL

      -- Exclu les conventions avec RI avec renonciation
		DELETE #C400
	    FROM #C400 #C4
	    JOIN Un_Cotisation CT ON CT.CotisationID = #C4.CotisationID
	    JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
	    JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	    JOIN Un_IntReimb RI ON RI.UnitID = U.UnitID
	    WHERE U.IntReimbDate IS NOT NULL
	          AND CESGRenonciation = 1

	  -- Exclu les conventions avec un RI, sans SCEE de base reçue à la date de ce RI 
		DELETE #C400
		FROM #C400 #C4
		JOIN Un_Cotisation CT ON CT.CotisationID = #C4.CotisationID
		JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	   LEFT JOIN (	
				  SELECT C4.ConventionID,
					fCESG = SUM(
						CASE 
							WHEN C4.iReversedCESP400ID IS NOT NULL THEN ISNULL(C9.fCESG,-ISNULL(CE.fCESG,0))
						ELSE ISNULL(C9.fCESG,ISNULL(CE.fCESG,0))
				       END)  -- SCEE.
			       FROM Un_CESP400 C4
				   JOIN dbo.Un_Unit U ON U.ConventionID = C4.ConventionID
				   JOIN Un_Oper O ON O.OperID = C4.OperID
			  LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
			  LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
			  LEFT JOIN Un_CESPReceiveFile R ON R.iCESPReceiveFileID = ISNULL(C9.iCESPReceiveFileID,S.iCESPReceiveFileID)
			  LEFT JOIN Un_CESP CE ON (CE.OperID = O.OperID AND CE.ConventionID = C4.ConventionID) 
			  LEFT JOIN Un_Oper OS ON OS.OperID = R.OperID
				  WHERE OS.OperDate <= U.IntReimbDate
			   GROUP BY C4.ConventionID
				) CE ON CE.ConventionID = #C4.ConventionID
		 WHERE U.IntReimbDate IS NOT NULL
		   AND ISNULL(CE.fCESG,0) = 0
      
	  -- 2009-11-26 : JFG : Exclusion des enregistrements 400 qui ne sont pas liés au bénéficiaire actuel de la convention.
	  DELETE tmp
	  FROM
		#C400 tmp	
		INNER JOIN dbo.Un_Convention c
			ON c.ConventionID = tmp.ConventionID
		INNER JOIN
		(
					SELECT 
						ch2.iID_Convention, ch2.iID_Nouveau_Beneficiaire, ch2.dtDate_Changement_Beneficiaire
					FROM
						dbo.tblCONV_ChangementsBeneficiaire ch2
						INNER JOIN
							(
							SELECT
								tmp.iID_Convention, 
								dtDate_Changement_Beneficiaire = MAX(tmp.dtDate_Changement_Beneficiaire)
							FROM
								dbo.tblCONV_ChangementsBeneficiaire tmp
							GROUP BY 
								tmp.iID_Convention
							) ch1
								ON ch2.iID_Convention = ch1.iID_Convention AND ch2.dtDate_Changement_Beneficiaire = ch1.dtDate_Changement_Beneficiaire
				) cb
						ON cb.iID_Convention = c.ConventionID
	  WHERE
		c.BeneficiaryID <> cb.iID_Nouveau_Beneficiaire

      --On calcule le nombre d'enregistrements 511 à généré 
      SELECT @iResult = COUNT(*)FROM #C400
      IF @iResult > 0 --S'il ya des enregistrements 511 à généré
      BEGIN          
      --Début de transaction
       BEGIN TRANSACTION

			--Supprimer les enregistrements 511 qui ont un iCESPSendFileID NULL
			BEGIN
			DELETE FROM UN_CESP511 WHERE iCESPSendFileID IS NULL
				
                IF @@ERROR <> 0
				 SET @iResult = -1 --Une erreur sql s'est produite lors de la suppression des 511
		    END
            
            --On Crée les enregistrements 511
            IF @iResult > 0
            BEGIN  
		   
             INSERT INTO UN_CESP511(
				iBeneficiaryID,
				ConventionID,
				iOriginalCESP400ID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,          
				vcOriginalTransID,
				vcPCGSINorEN,
				vcPCGFirstName,
				vcPCGLastName,
				tiPCGType)
                 
             SELECT 
				C.BeneficiaryID,
				C4.ConventionID,
				C4.iCESP400ID,
				'PCG',
				C4.dtTransaction,
				C4.iPlanGovRegNumber,
                C4.ConventionNo,
				C4.vcTransID,
                B.vcPCGSINorEN,
				B.vcPCGFirstName,
				B.vcPCGLastName,
				B.tiPCGType
              FROM #C400 #C4
        INNER JOIN UN_CESP400 C4 ON #C4.iCESP400ID = C4.iCESP400ID
              JOIN dbo.Un_Convention C ON C.ConventionID = C4.ConventionID
              JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				
            IF @@ERROR <> 0
				  SET @iResult = -2  -- Erreur lors de la création des enregistrements 511
       
           END
		-- Inscrit le vcTransID avec le ID PCG + <iCESP511ID>.
        IF @iResult > 0
         BEGIN
         
			UPDATE UN_CESP511
			   SET vcTransID = 'PCG'+CAST(iCESP511ID AS VARCHAR(12))
			 WHERE vcTransID = 'PCG'
            
            IF @@ERROR <> 0
             SET @iResult = -3 --Une erreur s'est produit lors de la mise à jour des 511
           
         END
        
		--On supprime la table temporaire
         IF @iResult > 0
         BEGIN
		    DROP TABLE #C400
             IF @@ERROR <> 0
                SET @iResult = -4 --Une erreur s'est produite lors de la suppression de la table temporaire 
         END
      --Si aucune erreur ne s'est produite on commite la transaction
    IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------
END
RETURN @iResult
END


