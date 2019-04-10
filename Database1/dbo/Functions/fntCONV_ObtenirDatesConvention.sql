
/****************************************************************************************************
Code de service		:		fntCONV_ObtenirDatesConvention
Nom du service		:		Obtenir les dates d’une convention 
But					:		Récupérer les dates clé d’une convention
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        iIdConvention	            Identifiant unique de la convention      Oui
						
Exemple d'appel:
                
                SELECT * FROM dbo.fntCONV_ObtenirDatesConvention (315747, '2009-01-01')

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Un_Convention	            dtEntreeVigueur	                            Date d’entrée en vigueur (plus petite date d'entrée en vigueur du groupe d'unités.)
						Un_Modal  
                        Un_Plan  
                        Un_Unit	                    dtRembEstime	                            Date Estimée de remboursement 
						Un_Convention  
                        Un_Modal  
                        Un_Plan  
                        Un_Unit	                    dtFinCotisation	                            Date de fin de cotisation (date théorique du dernier dépôt)
						Un_Convention	            dtInforceDateTIN	                        Date d’entrée en vigueur minimale des opérations TIN
						Un_Convention	            dtRegStartDate	                            Date de début de régime
						Un_Convention	            dtFirsPmtDate	                            Date du premier prélèvement de la convention 
						Un_Unit	                    UnitID	                                    Identifiant du groupe d’unité
						Un_Unit	                    dtMinInforceDateTIN	                        Plus petite date d’entrée en vigueur minimale des opérations TIN
						Un_Unit	                    dtMinSignatureDate	                        Plus petite date de signature du groupe d'unités.
						Un_Unit	                    dtMinIntReimbDate	                        Plus petite date de remboursement intégral du groupe d'unités.
						Un_Unit	                    dtMinIntReimbDateAdjust	                    Plus petite date ajustée de remboursement intégral

                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-03					Fatiha Araar							Création de la fonction           
						2009-09-08					Jean-François Gauthier					Modification pour calculer la date de remboursement
																							estimé (élimination de l'appel à la fonction FN_UN_EstimatedIntReimbDate)
						2009-10-09					Jean-François Gauthier					Ajout du UnitID en retour
						2009-11-05					Jean-François Gauthier					Ajout de la date d'échéance
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fntCONV_ObtenirDatesConvention]
						(	
							@iIdConvention INT,
							@dtDate DATETIME	
						)
RETURNS TABLE 
AS
RETURN 
( 
	SELECT  
		  dtEntreeVigueur		=	U.InForceDate --Date d'Entrée en vigueur du groupe d'unités. 
		  ,dtEcheance			=	MAX(dbo.FN_UN_EstimatedIntReimbDate(M.PmtByYearID,M.PmtQty,M.BenefAgeOnBegining,U.InForceDate,P.IntReimbAge,U.IntReimbDateAdjust))
		  ,dtRembEstime			=	DATEADD(yy, P.tiAgeQualif, h.BirthDate)
          ,dtFinCotisation		=	MAX( CASE 
										WHEN ISNULL(U.LastDepositForDoc,0) <= 0 THEN
											 dbo.fn_Un_LastDepositDate(U.InForceDate,C.FirstPmtDate,M.PmtQty,M.PmtByYearID)
										ELSE
											U.LastDepositForDoc
									  END)--Date de fin de cotisation
          ,dtFinRegime			= MAX( CASE 
										 WHEN dtCotisationEndDateAdjust IS NOT NULL THEN dtCotisationEndDateAdjust
										 WHEN U.LastDepositForDoc IS NOT NULL AND dtCotisationEndDateAdjust IS NULL THEN U.LastDepositForDoc
										ELSE DATEADD(year,A.YearQty,U.InForceDate )
										END)--Date de fin de cotisation
          ,dtInforceDateTIN		= C.dtInforceDateTIN--la date d’entrée en vigueur minimale des opérations TIN
          ,dtRegStartDate		= C.dtRegStartDate--Date de début de régime
          ,dtFirsPmtDate		= C.FirstPmtDate--Date du premier prelevement de la convention
          ,dtMinInforceDateTIN	= MIN(U.dtInforceDateTIN)--la plus petite date d’entrée en vigueur minimale des opérations TIN
          ,dtMinSignatureDate	= MIN(U.SignatureDate)--la plus petite date de signature du groupe d'unités
          ,dtMinIntReimbDate	= MIN(U.IntReimbDate)--la plus petite date de remboursement intégral du groupe d'unités
          ,dtMinIntReimbDateAdjust	= MIN(IntReimbDateAdjust)--la plus petite date ajustée de remboursement intégral
          ,ConventionID				= C.ConventionID
		  ,u.UnitID
   FROM 
		dbo.Un_Convention C 
		INNER JOIN dbo.Un_Unit U 
			ON U.ConventionID = C.ConventionID
		INNER JOIN dbo.Un_Modal M 
			ON M.ModalID = U.ModalID
		INNER JOIN dbo.Un_Plan P 
			ON P.PlanID = C.PlanID
		INNER JOIN dbo.Mo_Human h 
			ON h.HumanID = c.BeneficiaryID
		LEFT OUTER JOIN 
		(
		SELECT
			M.EffectDate,
			ISNULL(MIN(M2.EffectDate)-1, dbo.fn_CRQ_DateNoTime(GETDATE())) AS EndDate,
			M.YearQty
		FROM 
			dbo.Un_MaxConvDepositDateCfg M
			LEFT OUTER JOIN Un_MaxConvDepositDateCfg M2 
				ON	M2.EffectDate > M.EffectDate OR (M2.EffectDate = M.EffectDate 
					AND M2.MaxConvDepositDateCfgID > M.MaxConvDepositDateCfgID)
		GROUP BY
			M.EffectDate,
			M.YearQty
		) A 
			ON  U.InForceDate BETWEEN A.EffectDate AND A.EndDate
  WHERE 
		C.ConventionID = @iIdConvention 
		AND 
		U.TerminatedDate IS NULL
		AND 
		U.IntReimbDate IS NULL
  GROUP BY 
		C.ConventionID,
		U.UnitID,
		U.InForceDate,
		C.dtInforceDateTIN,
		C.dtRegStartDate,
		C.FirstPmtDate,
		P.tiAgeQualif, 
		H.BirthDate
  HAVING
		MIN(U.InForceDate) <= @dtDate
)
