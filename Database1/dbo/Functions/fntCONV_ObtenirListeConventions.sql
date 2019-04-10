/****************************************************************************************************
Code de service :   fntCONV_ObtenirListeConventions
Nom du service	 :	Obtenir les conventions 
But			 :	Récupérer les conventions REE d'un souscripteur
				Récupérer les conventions REE d'un bénéficiaire
				Récupérer les conventions d'un bénéficiaire ainsi que les conventions lui ayant déjà appartenue
							
Facette		 :   P171U
Reférence		 :	Relevé de dépôt

Parametres d'entrée :
        Parametres			  Obligatoire     Description
        --------------------    -----------     --------------------------------------------
        dtDateReleve	       Oui             La date du relevé
        iIDSouscripteur         Non             Identifiant unique du souscripteur, mais doit être passé à NULL si non utilisé
        iIDBeneficiaire		  Non             Identifiant unique du bénéficiaire, mais doit être passé à NULL si non utilisé
        bListeComplete		  Oui             Indique si on doit retourner la liste complète des conventions d'un bénéficiaire	

N.B.
	Les paramètres 	iIDSouscripteur et iIDBeneficiaire sont indépendants l'un de l'autre. Autrement dit,
	ils ne devraient jamais recevoir une valeur spécifique en même temps. Si jamais c'est le cas, la requête
	liée à iIDSouscripteur aura préséance. Il en sera de même si les 2 paramètres sont passés avec la valeur
	NULL.


Exemple d'appel:

        -- Recherche des conventions REE pour un souscripteur donné
        SELECT * FROM dbo.fntCONV_ObtenirListeConventions('2008-12-31',380489, NULL, 0) -- retourne 3 enregistrements

        -- Recherche des conventions REE pour tous les souscripteurs
        --SELECT * FROM dbo.fntCONV_ObtenirListeConventions('2008-12-31',NULL, NULL, 0)

        -- Recherche des conventions REE pour un bénéficiaire
        SELECT * FROM dbo.fntCONV_ObtenirListeConventions('2009-10-15', NULL, 556263, 0)

        -- Recherche de l'ensemble des conventions ayant appartenu à un bénéficiaire
        SELECT * FROM dbo.fntCONV_ObtenirListeConventions('2009-10-15', NULL, 556263, 1)           

Parametres de sortie :  

        Table				  Champs					Description
	   -----------------	  ------------------------    --------------------------
        Un_Convention	       ConventionID	               Identifiant unique de la convention
						  SubscriberID	               Identifiant unique du souscripteur
						  BeneficiaryID	          Identifiant unique du bénéficiaire
						  ConventionNo				Numéro de la convention
        Un_Plan                 PlanDesc                    Description du régime            
						  PlanTypeID                  Code du régime
						
	   N/A				  bBeneficiaireActuel		Indique si le bénéficiaire passé en paramètre est celui en cours sur la convention
						  bFormulaireRecu			Indique si le formulaire RHDSC est reçu sur la convention
						  bBECActif				Indique si le BEC est actif sur la convention
						  bConventionResilie		Indique si la convention est résiliée
						  mMontantBEC				Montant du BEC

                    
Historique des modifications :
			
        Date		    Programmeur				 Description
        ----------	    ----------------------------    --------------------------------------------------------------
        2009-01-13	    Fatiha Araar				 Création de la fonction
        2009-01-21      Fatiha Araar                    Correction
        2009-02-06      Fatiha Araar                    Ajouter l'affichage du PlanTypeID
        2009-10-21	    Jean-François Gauthier		 Modification afin de répondre aux besoins du BEC et des changements de bénéficiaires
        2009-10-28	    Jean-François Gauthier		 Ajout des champs liés au bénéficiaires
        2009-11-04	    Jean-François Gauthier		 Ajout des champs iIDConventionBEC, iIDConventionBECSuggere
        2009-11-05	    Jean-François Gauthier		 Ajout du champ iIDUniteBEC
        2009-12-09	    Jean-François Gauthier		 Ajout du paramètre de plus à l'appel à fnCONV_ObtenirConventionBEC
        2010-02-02	    Jean-François Gauthier		 Modification de l'appel à fntCONV_RechercherChangementsBeneficiaire
        2010-02-15	    Pierre Paquet				 Ajustement au montant du BEC afin de calculer correctement le remboursement.
        2010-02-16	    Jean-François Gauthier		 Optimisation
        2010-05-04	    Pierre Paquet				 Afficher la convention dont il est le bénéf actuel sans passer par l'historique.
        2010-05-07	    Pierre Paquet				 Case BEC uniquement si c'est le bénéf de la convention.
        2015-07-29      Steve Picard				 Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
        2015-12-01      Steeve Picard                   Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
***********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirListeConventions]
(	
    @dtDateReleve		DATETIME
    ,@iIDSouscripteur	INT = NULL
    ,@iIDBeneficiaire	INT = NULL	
    ,@bListeComplete	BIT	
)
RETURNS @tResultat TABLE (
        ConventionID					INT
        ,SubscriberID					INT
        ,BeneficiaryID					INT
        ,ConventionNo					VARCHAR(15)
        ,PlanDesc						VARCHAR(75)
        ,PlantypeID						CHAR(3)
        ,TextDiploma					VARCHAR(150)
        ,bBeneficiaireActuel			BIT
        ,bFormulaireRecu				BIT
        ,bBECActif						BIT
        ,bConventionResilie				BIT
        ,mMontantBEC					MONEY
        ,vcNomBeneficiaire				VARCHAR(75)
        ,vcPrenomBeneficiaire			VARCHAR(75)
        ,vcNomSouscripteur				VARCHAR(75)
        ,vcPrenomSouscripteur			VARCHAR(75)
        ,bPrincipalResponsablePresent	BIT
        ,vcStatutConvention				VARCHAR(3)
        ,iIDConventionBEC				INT
        ,iIDConventionBECSuggere		INT
        ,iIDUniteBEC					INT
    )
AS
BEGIN
    -- RETOURNE LES CONVENTIONS REE D'UN SOUSCRIPTEUR OU DE TOUS LES SOUSCRIPTEURS
    IF (@bListeComplete = 0)
	   BEGIN
		  INSERT INTO @tResultat (
				ConventionID	
				,SubscriberID	
				,BeneficiaryID	
				,ConventionNo	
				,PlanDesc		
				,PlantypeID		
				,TextDiploma	
				,bBeneficiaireActuel
				,bFormulaireRecu	
				,bBECActif			
				,bConventionResilie	
				,mMontantBEC
				,iIDConventionBEC
				,iIDConventionBECSuggere
				,iIDUniteBEC
			 )
	       SELECT DISTINCT					
		          c.ConventionID
		          ,c.SubscriberID 
		          ,c.BeneficiaryID
		          ,c.ConventionNo
		          ,p.PlanDesc
		          ,p.PlantypeID
		          ,c.TexteDiplome			-- 2015-07-29
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN 1 ELSE 0 END
				,CASE WHEN (c.BeneficiaryID = @iIDBeneficiaire) AND (c.bFormulaireRecu = 1) THEN 1 ELSE 0 END
				--,dbo.fnPCEE_ValiderPresenceBEC(c.ConventionID)
				,c.bCLBRequested
				,CASE WHEN s.ConventionStateID = 'FRM' THEN 1 ELSE 0 END
				--	,CASE	WHEN c.BeneficiaryID = @iIDBeneficiaire THEN ISNULL((SELECT SUM(ce.fCLB) FROM dbo.Un_CESP ce WHERE ce.ConventionID = c.ConventionID)+ISNULL((SELECT SUM(c4.fCLB) FROM dbo.Un_CESP400 C4 WHERE C4.ConventionID = c.ConventionID AND iCESPSendFILEID IS NULL AND tiCESP400TypeID = 21),0),0)
				/*	,CASE	WHEN c.BeneficiaryID = @iIDBeneficiaire THEN ISNULL((SELECT SUM(ce.fCLB) FROM dbo.Un_CESP ce WHERE ce.ConventionID = c.ConventionID)+ISNULL((SELECT SUM(c4.fCLB) FROM dbo.Un_CESP400 C4 WHERE C4.ConventionID = c.ConventionID AND tiCESP400TypeID = 21 AND (iCESPSendFILEID IS NULL OR C4.iCESP400ID NOT IN (SELECT iCESP400ID FROM UN_CESP900))),0),0)
							 ELSE 0
				END */
				/*	,CASE	WHEN c.BeneficiaryID = @iIDBeneficiaire THEN ISNULL((SELECT SUM(ce.fCLB) FROM dbo.Un_CESP ce WHERE ce.ConventionID = c.ConventionID)+ISNULL((SELECT SUM(c4.fCLB) 
																				    FROM dbo.Un_CESP400 C4 WHERE C4.ConventionID = c.ConventionID AND tiCESP400TypeID = 21 AND (iCESPSendFILEID IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.UN_CESP900 ce9 WHERE ce9.iCESP400ID = C4.iCESP400ID))),0),0)
						  ELSE 0
				END */
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire 
                            THEN ISNULL(
                                    (SELECT SUM(ce.fCLB) FROM dbo.Un_CESP ce WHERE ce.ConventionID = c.ConventionID)
					           +
							 ISNULL(
                                        (   SELECT  SUM(c4.fCLB) 
                                            FROM    dbo.Un_CESP400 C4 LEFT OUTER JOIN dbo.UN_CESP900 ce9 ON ce9.iCESP400ID = C4.iCESP400ID
								    WHERE   C4.ConventionID = c.ConventionID 
								        AND C4.tiCESP400TypeID = 21
                                                AND (   C4.iCESPSendFILEID IS NULL
                                                        OR ce9.iCESP400ID IS NULL 
                                                        --NOT EXISTS(SELECT 1 FROM dbo.UN_CESP900 ce9 WHERE ce9.iCESP400ID = C4.iCESP400ID)
										  )
                                        ), 0), 0)
			             ELSE 0
				END
				,dbo.fnCONV_ObtenirConventionBEC(@iIDBeneficiaire, 0, NULL)
				,dbo.fnCONV_ObtenirConventionBEC(@iIDBeneficiaire, 1, NULL)
				,dbo.fnPCEE_ObtenirUniteBEC(c.ConventionNo)
		  FROM 
			     dbo.Un_Convention c 
                    INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(ISNULL(@dtDateReleve, GETDATE()), NULL) s
                        ON s.conventionID = c.ConventionID
			     --LEFT OUTER JOIN dbo.Un_DiplomaText d ON d.DiplomaTextID = c.DiplomaTextID		-- 2015-07-29
			     INNER JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
			     INNER JOIN dbo.Un_Plan P ON p.PlanID = c.PlanID
		  WHERE 
			     c.BeneficiaryID = ISNULL(@iIDBeneficiaire, c.BeneficiaryID)
                AND c.SubscriberID		= ISNULL(@iIDSouscripteur, c.SubscriberID)
			 AND (   u.TerminatedDate	IS NULL			-- DATE DE RÉSILIATION
				    OR u.IntReimbDate		IS NULL			-- DATE DE REMBOURSEMENT INTÉGRAL			
				)
                AND s.ConventionStateID = 'REE' -- L'état REEE  
			 --AND u.InForceDate		< @dtDateReleve	-- DATE D'ENTRÉE EN VIGUEUR DU GROUPE D'UNITÉ
	   END    
    ELSE	-- @bListeComplete = 1 (NE TIENT COMPTE QUE DE L'IDENTIFIANT DU BÉNÉFICIAIRE
	   BEGIN
	       INSERT INTO @tResultat (
                    ConventionID	
                    ,SubscriberID	
                    ,BeneficiaryID	
                    ,ConventionNo	
                    ,PlanDesc		
                    ,PlantypeID		
                    ,TextDiploma	
                    ,bBeneficiaireActuel
                    ,bFormulaireRecu	
                    ,bBECActif			
                    ,bConventionResilie	
                    ,mMontantBEC
                    ,iIDConventionBEC
                    ,iIDConventionBECSuggere	
                    ,iIDUniteBEC	
                )
            SELECT DISTINCT
				c.ConventionID
				,c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionNO
				,p.PlanDesc	
				,p.PlanTypeID
				,c.TexteDiplome			-- 2015-07-29
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN 1 ELSE 0 END
				,CASE WHEN (c.BeneficiaryID = @iIDBeneficiaire) AND (c.bFormulaireRecu = 1) THEN 1 ELSE 0 END
				--,dbo.fnPCEE_ValiderPresenceBEC(c.ConventionID)
				--,c.bCLBRequested
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN c.bCLBRequested ELSE 0 END
				,CASE WHEN s.conventionStateID = 'FRM' THEN 1 ELSE 0 END
                    --,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN ISNULL((SELECT SUM(ce.fCLB) FROM dbo.Un_CESP ce WHERE ce.ConventionID = c.ConventionID),0)
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN ISNULL((SELECT SUM(ce.fCLB) FROM dbo.Un_CESP ce WHERE ce.ConventionID = c.ConventionID)+ISNULL((SELECT SUM(c4.fCLB) FROM dbo.Un_CESP400 C4 WHERE C4.ConventionID = c.ConventionID AND tiCESP400TypeID = 21 AND (iCESPSendFILEID IS NULL OR C4.iCESP400ID NOT IN (SELECT iCESP400ID FROM UN_CESP900))),0),0)
					 ELSE 0
				END
				,dbo.fnCONV_ObtenirConventionBEC(@iIDBeneficiaire, 0, NULL)
				,dbo.fnCONV_ObtenirConventionBEC(@iIDBeneficiaire, 1, NULL)
				,dbo.fnPCEE_ObtenirUniteBEC(c.ConventionNo)
		  FROM
				dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @iIDBeneficiaire) fnt
				INNER JOIN dbo.Un_Convention c ON c.ConventionID = fnt.iID_Convention
                    INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(ISNULL(@dtDateReleve, GETDATE()), NULL) s ON s.conventionID = C.conventionID
				--LEFT OUTER JOIN dbo.Un_DiplomaText d ON d.DiplomaTextID = c.DiplomaTextID		-- 2015-07-29
				INNER JOIN dbo.Un_Plan p ON p.PlanID = c.PlanID
					
		  -- Récupérer la ou les conventions actives (vieux changement de bénéficiare non-présent dans tblCONV_ChangementsBeneficiaire
		  INSERT INTO @tResultat (
				ConventionID	
				,SubscriberID	
				,BeneficiaryID	
				,ConventionNo	
				,PlanDesc		
				,PlantypeID		
				,TextDiploma	
				,bBeneficiaireActuel
				,bFormulaireRecu	
				,bBECActif			
				,bConventionResilie	
				,mMontantBEC
				,iIDConventionBEC
				,iIDConventionBECSuggere	
				,iIDUniteBEC	
			 )
		  SELECT DISTINCT
				c.ConventionID
				,c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionNO
				,p.PlanDesc	
				,p.PlanTypeID
				,c.TexteDiplome			-- 2015-07-29
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN 1 ELSE 0 END
				,CASE WHEN (c.BeneficiaryID = @iIDBeneficiaire) AND (c.bFormulaireRecu = 1) THEN 1 ELSE 0 END
				--,c.bCLBRequested -- 2010-05-07 Pierre Paquet 
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN c.bCLBRequested ELSE 0 END
				,CASE WHEN s.conventionStateID = 'FRM' THEN 1 ELSE 0 END
				,CASE WHEN c.BeneficiaryID = @iIDBeneficiaire THEN ISNULL((SELECT SUM(ce.fCLB) FROM dbo.Un_CESP ce WHERE ce.ConventionID = c.ConventionID)+ISNULL((SELECT SUM(c4.fCLB) FROM dbo.Un_CESP400 C4 WHERE C4.ConventionID = c.ConventionID AND tiCESP400TypeID = 21 AND (iCESPSendFILEID IS NULL OR C4.iCESP400ID NOT IN (SELECT iCESP400ID FROM UN_CESP900))),0),0)
					 ELSE 0
				END
				,dbo.fnCONV_ObtenirConventionBEC(@iIDBeneficiaire, 0, NULL)
				,dbo.fnCONV_ObtenirConventionBEC(@iIDBeneficiaire, 1, NULL)
				,dbo.fnPCEE_ObtenirUniteBEC(c.ConventionNo)
		  FROM
			     dbo.Un_Convention c
                    INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(ISNULL(@dtDateReleve, GETDATE()), NULL) s ON s.conventionID = C.conventionID
			     --LEFT OUTER JOIN dbo.Un_DiplomaText d ON d.DiplomaTextID = c.DiplomaTextID		-- 2015-07-29
			     INNER JOIN dbo.Un_Plan p ON p.PlanID = c.PlanID
		  WHERE
                    c.conventionID NOT IN (SELECT ConventionID FROM @tResultat)
			 AND c.BeneficiaryID = @iIDBeneficiaire
    END    

    RETURN
END
