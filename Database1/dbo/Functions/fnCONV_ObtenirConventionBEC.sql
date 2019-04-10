/***********************************************************************************************************************
Code de service		:		fnCONV_ObtenirConventionBEC
Nom du service		:		fnCONV_ObtenirConventionBEC
But					:		
Facette				:		CONV
Reférence			:		
 
Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------
						iID_Beneficiaire			Identifiant du bénéficiaire					Oui
						bBECSuggere					Indique si on désire obtenir la convention  Oui
													suggérée pour la demande de BEC d'un
													bénéficiaire (= 1 si oui, 0 sinon)	
						idConventionExluse			Identifiant de la convention à exclure		Non
 
Exemples d'appel:
		SELECT [dbo].[fnCONV_ObtenirConventionBEC](556346, 0, NULL)	
		SELECT [dbo].[fnCONV_ObtenirConventionBEC](123843, 1, NULL)	
 
Parametres de sortie :
 
        Table			    Champs				 Description
	   -----------------   ------------------------    --------------------------
	   Un_Convention	    iID_Convention			 Identifiant de la convention suggérée pour la demande de BEC
	   N/A			    @iCodeRetour			 > 0 (contient l'identifiant de la convention)
											 < 0 (code d'erreur)
											     = -1 Impossible de trouver une convention dont le BEC est activé
												= -2 si les information du principal responsable sont incomplètes (bBECSuggere = 1)
												= -3 si impossible de récupérer la convention BEC selon l'ordre suivant (bBECSuggere = 1) :
												- PLUS VIEILLE CONVENTION INDIVIDUELLE
												- SINON PLUS VIEILLE CONVENTION COLLECTIVE REEFLEX
												- SINON PLUS VIEILLE CONVENTION COLLECTIVE UNIVERSITAS
 
Historique des modifications :
 
        Date		    Programmeur				 Description
        ----------      ----------------------------    --------------------------------------------------------------
        2009-10-15	    Jean-François Gauthier          Création de la fonction
        2009-11-03      Jean-François Gauthier		 Modification afin de gérer aussi l'obtention des conventions BEC suggérées
        2009-12-07	    Jean-François Gauthier		 Ajout du paramètre idConventionExluse permettant d'exclure
        2009-12-24	    Jean-François Gauthier		 Modification dans la section d'obtention de la convention BEC la plus récente
        2010-01-21      Pierre Paquet				 Vérification uniquement de la case 'BEC'
        2010-04-16	    Jean-François Gauthier		 Modification afin d'exclure les conventions fermées
        2010-05-03	    Pierre Paquet				 Correction convention suggérée.
        2010-10-25	    Pierre Paquet				 Ajout de la validation du RI.
        2012-11-07	    Donald Huppé				 Dans LA LISTE DE TOUTES LES CONVENTIONS ACTIVES DU BÉNÉFICIARE, on recherche les convention = REE et non les convention <> FRM.
											 Afin de ne pas utliser les conventions TRA
        2014-11-21	    Pierre-Luc Simard			 Ajout du filtre sur le champ SCEEFormulaire93BECRefuse	
        2015-12-01      Steeve Picard                   Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
        2017-09-12      Steeve Picard               Ajout du filtre sur le champ SCEEAnnexeBPRespRequise & SCEEAnnexeBPRespRecue
***********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirConventionBEC]
(
	@iID_Beneficiaire		INT
	,@bBECSuggere			BIT
	,@idConventionAExclure	INT
)
RETURNS INT
AS
	BEGIN
		DECLARE @iID_Convention INT	
				,@iCodeRetour	INT
 
		IF @bBECSuggere = 0		-- OBTENIR LA CONVENTION BEC
			BEGIN
				-- Vérifier s'il y a plus d'une convention 'BEC' pour le même bénéficiaire.  Si oui, alors il y a une erreur dans les données.
				IF (SELECT COUNT(*) FROM dbo.Un_Convention WHERE BeneficiaryID = @iID_Beneficiaire and bCLBRequested = 1) > 1
					BEGIN
						SET @iCodeRetour = -1
						GOTO SortieFonction
					END
 
				-- Récupérer la convention 'BEC' du bénéficiaire.
				SELECT
					@iID_Convention = ce.ConventionID
				FROM
					UN_Convention ce where BeneficiaryID = @iID_Beneficiaire and bCLBRequested = 1
			RETURN 	@iID_Convention
			END
		ELSE					-- OBTENIR LA CONVENTION BEC SUGGÉRÉE
			BEGIN
 
				-- VALIDATION #1 - Vérifier si le bénéficiare a déjà le BEC.
				--IF EXISTS(SELECT 1 FROM dbo.Un_Convention ce where BeneficiaryID = @iID_Beneficiaire and bCLBRequested = 1)
				IF EXISTS(SELECT 1 FROM dbo.Un_Convention ce where BeneficiaryID = @iID_Beneficiaire and bCLBRequested = 1 and ce.conventionID <> @idConventionAExclure)
					BEGIN
						SET @iCodeRetour = -1
						GOTO SortieFonction
					END
 
				-- VALIDATION #2 - VÉRIFIER SI LES INFORMATIONS DU PRINCIPAL RESPONSABLE DU BÉNÉFICIAIRE SONT PRÉSENTES
				IF EXISTS(	SELECT 1
							FROM dbo.Un_Beneficiary b
							WHERE
								b.BeneficiaryId = @iID_Beneficiaire
								AND (	b.vcPCGSINorEN IS NULL
										OR
										b.vcPCGFirstName IS NULL
										OR
										b.vcPCGLastName IS NULL )
						 )
					BEGIN
						SET @iCodeRetour = -2
						GOTO SortieFonction
					END
 
				-- Récupérer la convention BEC suggérée.
				DECLARE @tConvention	TABLE
							(			
							iID_Convention			INT
							,iID_Souscripteur		INT
							,iID_Beneficiaire		INT
							,vcConventionNO			VARCHAR(75)
							,cID_PlanType			CHAR(3)
							,vcPlanDesc				VARCHAR(75)
							,dtDateEntreeVigueur	DATETIME
							)
 
				-- 1.	FAIRE LA LISTE DE TOUTES LES CONVENTIONS ACTIVES DU BÉNÉFICIARE QUI ONT ENVOYÉ
				--		LE FORMULAIRE RHDSC
				INSERT INTO @tConvention
				(
				iID_Convention		
				,iID_Souscripteur	
				,iID_Beneficiaire	
				,vcConventionNO		
				,cID_PlanType		
				,vcPlanDesc			
				,dtDateEntreeVigueur		
				)
				SELECT
					fnt.iConventionID
					,fnt.iSubscriberID
					,fnt.iBeneficiaryID
					,fnt.vcConventionNO
					,fnt.cPlanTypeID
					,fnt.vcPlanDesc
					,u.InForceDate
				FROM
					dbo.fntCONV_ObtenirListeConventionsParBeneficiaire(GETDATE(), @iID_Beneficiaire) fnt	-- LISTE DES CONVENTION REE ACTIVES
					INNER JOIN dbo.Un_Beneficiary b
						ON fnt.iBeneficiaryID = b.BeneficiaryID
					INNER JOIN dbo.Un_Unit u
						ON u.ConventionID = fnt.iConventionID
					INNER JOIN dbo.Un_Convention c
						ON c.ConventionID = fnt.iConventionID
                    INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GetDate(), NULL) s
                        ON s.conventionID = c.ConventionID
				WHERE
					c.bFormulaireRecu	= 1		-- FORMULAIRE RHDSC REÇU
                    AND CASE WHEN C.SCEEAnnexeBPRespRequise = 1 THEN C.SCEEAnnexeBPRespRecue ELSE 1 END = 1
                    AND s.ConventionStateID = 'REE'  -- D Huppé 2012-11-07 --<> 'FRM' -- 2010-04-16 : JFG : SUPPRESSION DES CONVENTIONS FERMÉES
					AND NOT EXISTS(	SELECT 1 FROM dbo.Un_Unit ut WHERE ut.ConventionID = C.ConventionID AND ut.IntReimbDate IS NOT NULL) -- 2010-10-24 PPA: Pas de RI.
					AND ISNULL(C.SCEEFormulaire93BECRefuse, 0) = 0 -- Pas de BEC refusé
 
				-- 2009-12-07	: SUPPRESSION DE LA CONVENTION À EXCLURE SI PRÉSENTE
				IF @idConventionAExclure IS NOT NULL
					BEGIN
						DELETE FROM @tConvention WHERE iID_Convention = @idConventionAExclure
					END
 
				-- 4.	RÉCUPÉRER LA CONVENTION SUGGÉRÉE POUR LE BEC SELON L'ORDRE SUIVANT :
				--			- PLUS VIEILLE CONVENTION INDIVIDUELLE
				--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE REEFLEX
				--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE UNIVERSITAS
 
				SET @iID_Convention = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.cID_PlanType = 'IND' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)
 
				IF @iID_Convention IS NULL
					BEGIN
						SET @iID_Convention = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Reeeflex' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)
					END
 
				IF @iID_Convention IS NULL
					BEGIN
						SET @iID_Convention = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Universitas' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)				
					END
 
				SET @iCodeRetour = ISNULL(@iID_Convention, -3)	
 
			END
 
SortieFonction:
		RETURN @iCodeRetour
	END