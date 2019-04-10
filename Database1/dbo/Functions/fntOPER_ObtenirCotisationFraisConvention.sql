/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:		fnOPER_ObtenirCotisationFraisConvention
Nom du service		:		Obtenir les cotisations et frais d’une convention 
But					:		Récupérer la liste des cotisations et des frais d’une convention
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                                                     Obligatoir
                        ----------                  ----------------                                                --------------                       
                        iIDConvention	            Identifiant unique de la convention                             Oui
						iGroupeUnite	            Identifiant du groupe d’unités                                  Non
						dtDateDebut	                Date de début                                                   Non
						dtDateFin	                Date de fin                                                     Non
                        vcTypeDate                  Type de date à utiliser (E = Effectivité, O = Opération)        Oui
						vcCodeCategorie	            Catégorie d’opérations à renvoyer								Non
						cTypeRequete				Indique si les frais sont recherchés pour le sommare (S)		OUI
													ou le détail (D)


Exemple d'appel:
                
                SELECT * FROM dbo.fntOPER_ObtenirCotisationFraisConvention(322523,NULL,NULL,'2009-12-31','E',NULL,'D')

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       @tUn_CotisationsFrais        iIDGroupeUnite	                            Identifiant du groupe d’unité
					   @tUn_CotisationsFrais		fQteUnite	                                Quantité d’unités
					   @tUn_CotisationsFrais		mCotisation	                                Cotisation
					   @tUn_CotisationsFrais		EffectDate	                                Date d’effectivité
					   @tUn_CotisationsFrais		iID_Cotisation	                            Identifiant unique de la cotisation
					   @tUn_CotisationsFrais		mFrais	                                    Frais
					   @tUn_CotisationsFrais		IID_Oper	                                Identifiant unique de l’opération
					   @tUn_CotisationsFrais		dtDateOperation	                                Date de l’opération
					   @tUn_CotisationsFrais		vcTypeOperation	                                Type d’opération

                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-11-01					Fatiha Araar							Création de la fonction 
                        2009-01-07                  Fatiha Araar                            Ajouter le filtre Type de date à utiliser (E = Effectivité, O = Opération)         
						2009-10-02					Jean-François Gauthier					Correction du type du champ fQteUnite
						2010-03-11					Jean-François Gauthier					Modification pour le calcul des frais fixees des conventions individuelles
						2010-03-12					Jean-François Gauthier					Ajout du >= 12 pour les conventions T
																							Ajout du paramètre cTypeRequete		
						2010-03-15					Jean-François Gauthier					Remplacement du OperDate par EffectDate pour le calcul du 12 mois des
																							conventions 'T'
						2010-03-24					Jean-François Gauthier					Modification pour récupérer le champ vcCompany
																							avec le type de date "E"
						2011-03-11					Frédérick Thibault						Abolition de la validation de la règle des 12 mois si la date
																							de la convention 'T' entre dans la période validable (paramètre) (FT1)
                        2011-11-29                  Mbaye Diakhate				            Ajoute cas pour le calcul des cotisations dans le cas de @vcTypeDate = 'E'
                        2013-02-27					Pierre-Luc Simard						Ajout de vcCompany lors des OUT
                        2018-01-22                  Pierre-Luc Simard                       N'est plus utilisé                        
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirCotisationFraisConvention] 
					(	
						@iIDConvention		INT,
						@iGroupeUnite		INT ,
						@dtDateDebut		DATETIME ,
						@dtDateFin			DATETIME  ,
						@vcTypeDate			VARCHAR(2),
						@vcCodeCategorie	VARCHAR(100),
						@cTypeRequete		CHAR(1)
					)
RETURNS @tUn_CotisationsFraisConvention 
	TABLE (
			mCotisation			MONEY,
			dtDateEffective		DATETIME,
			iIDGroupeUnite		INT,
			fQteUnite			FLOAT,
			iID_Cotisation		INT,
			mFrais				MONEY,
			iID_Oper			INT,
			dtDateOperation		DATETIME,
			vcTypeOperation		CHAR(3),
			vcCompagnie			VARCHAR(200),
			mAutreRev			MONEY,
			iIDConvention		INT,
			iPayementParAnnee	INT,
			iNombrePayement		INT
		  )
BEGIN
    INSERT INTO @tUn_CotisationsFraisConvention
						 (
							mCotisation,dtDateEffective,iIDGroupeUnite,
							fQteUnite,iID_Cotisation,mFrais,iID_Oper,dtDateOperation,vcTypeOperation,
							vcCompagnie,mAutreRev,iIDConvention,iPayementParAnnee,iNombrePayement
						 )
    SELECT
        0,GETDATE(),1,
		1,1,0,1,GETDATE(),'',
		'',0,1,1,1/0
    /*
	IF @cTypeRequete = 'S' 
		BEGIN
			-- Recherche de la première date d'opration de la convention
			DECLARE 
				@dtMinOperDate					DATETIME
				,@iNb_Mois_Avant_RIN_Apres_RIO	INT
				
			SELECT @iNb_Mois_Avant_RIN_Apres_RIO = iNb_Mois_Avant_RIN_Apres_RIO FROM dbo.Un_Def
				
			SELECT
				@dtMinOperDate = MIN(U.InForceDate)
			FROM
				dbo.Un_Unit U
			WHERE
				U.ConventionID = @iIDConvention
			
			
			-- Recherche des frais et cotisations
			IF @iIDConvention IS NOT NULL AND @vcTypeDate IS NOT NULL
			 BEGIN
				 IF @vcTypeDate = 'O'
					 BEGIN
						 INSERT INTO @tUn_CotisationsFraisConvention
						 (
							mCotisation,dtDateEffective,iIDGroupeUnite,
							fQteUnite,iID_Cotisation,mFrais,iID_Oper,dtDateOperation,vcTypeOperation,
							vcCompagnie,mAutreRev,iIDConvention,iPayementParAnnee,iNombrePayement
						 )
						 SELECT 
								ISNULL(CT.Cotisation,0),CT.EffectDate,CT.UnitID,ISNULL(U.UnitQty,0),CT.CotisationID,
								ISNULL(CASE	
										WHEN p.PlanTypeID = 'IND' THEN 
											CASE
												WHEN UPPER(LEFT(CAST(cn.ConventionNo AS VARCHAR(15)),1)) IN ('I','F') THEN 200
												WHEN UPPER(LEFT(CAST(cn.ConventionNo AS VARCHAR(15)),1)) = 'T' THEN
													CASE
														-- FT1
														WHEN (SELECT dbo.fnGENE_ObtenirParametre (
																				'OPER_VALIDATION_12_MOIS'
																				,@dtMinOperDate
																				,NULL
																				,NULL
																				,NULL
																				,NULL
																				,NULL)) = 1 THEN
															CASE
																WHEN DATEDIFF(mm,@dtMinOperDate, @dtDateFin) <= @iNb_Mois_Avant_RIN_Apres_RIO THEN 
																	200
																ELSE 
																	0
															END
														ELSE
															0
													END
												ELSE
													CT.Fee
											END
										ELSE
											CT.Fee
										END,0),
								CT.OperID,O.OperDate,O.OperTypeID,
								Company = CASE O.OperTypeID
										  WHEN 'TIN' THEN ISNULL(C.CompanyName,'')
										  ELSE
										  ''
										  END,
								fAIP,ConventionID = U.ConventionID,M.pmtByYearID,M.pmtQty
         				  FROM 
								dbo.Un_Unit U
								INNER JOIN dbo.Un_Modal M ON M.ModalID=U.ModalID
								INNER JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
		 						INNER JOIN dbo.Un_Oper O ON O.OperID = CT.OperID
								INNER JOIN dbo.Un_OperType OT ON OT.OperTypeID = O.OperTypeID
								LEFT OUTER JOIN dbo.Un_TIN T ON T.OperID = O.OperID
								LEFT OUTER JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID 
								LEFT OUTER JOIN dbo.Mo_Company C ON C.CompanyID = EP.ExternalPromoID
								LEFT OUTER JOIN dbo.Un_Plan p ON p.PlanID = M.planID
								LEFT OUTER JOIN dbo.Un_Convention cn ON cn.ConventionID = U.ConventionID
						 WHERE 
						   --Mbaye Diakhate: 2011-12-19: changer la condition  pour  prendre en compte les groupes d'unitéé résilié durant la période
						   --U.TerminatedDate IS NULL
						   (U.TerminatedDate IS NULL OR (U.TerminatedDate >=@dtDateDebut AND U.TerminatedDate <=@dtDateFin)) 
							AND U.IntReimbDate IS NULL
							AND
							 U.ConventionID = @iIDConvention
							AND (CT.UnitID = ISNULL(@iGroupeUnite,CT.UnitID))--ID du groupe d'unité
							AND (O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())) --Date debut et fin d'opperation
						
					END
				ELSE IF @vcTypeDate = 'E' --20111129 MBD CALCUL DES SOLDES DE INITIAL
					BEGIN
					 INSERT INTO @tUn_CotisationsFraisConvention
						 (
							mCotisation,dtDateEffective,iIDGroupeUnite,fQteUnite,
							iID_Cotisation,mFrais,iID_Oper,dtDateOperation,vcTypeOperation,
							vcCompagnie,mAutreRev,iIDConvention,iPayementParAnnee,iNombrePayement
						)
						 SELECT CT.Cotisation,
								CT.EffectDate,
								CT.UnitID,
								U.UnitQty,
								CT.CotisationID,
								CASE	
										WHEN p.PlanTypeID = 'IND' THEN 
											CASE
												WHEN UPPER(LEFT(CAST(c.ConventionNo AS VARCHAR(15)),1)) IN ('I','F') THEN 200
												WHEN UPPER(LEFT(CAST(c.ConventionNo AS VARCHAR(15)),1)) = 'T' THEN
													-- FT1
													--CASE
													--	WHEN DATEDIFF(mm,@dtMinOperDate, @dtDateFin) <= @iNb_Mois_Avant_RIN_Apres_RIO THEN 200
													--	ELSE 0
													--END
													CASE
														WHEN (SELECT dbo.fnGENE_ObtenirParametre (
																				'OPER_VALIDATION_12_MOIS'
																				,@dtMinOperDate
																				,NULL
																				,NULL
																				,NULL
																				,NULL
																				,NULL)) = 1 THEN
															CASE
																WHEN DATEDIFF(mm,@dtMinOperDate, @dtDateFin) <= @iNb_Mois_Avant_RIN_Apres_RIO THEN 
																	200
																ELSE 
																	0
															END
														ELSE
															0
													END

												ELSE	
													CT.Fee	
											END																				
										ELSE
											CT.Fee
								END,
								CT.OperID,
								O.OperDate,
								O.OperTypeID,
								Company = CASE O.OperTypeID
										  WHEN 'TIN' THEN ISNULL(cie.CompanyName,'')
										  ELSE
										  ''
										  END,
								0,
								conventionid = U.ConventionID,
								M.pmtByYearID,
								M.pmtQty
						  FROM 
							dbo.Un_Unit U
							INNER JOIN dbo.Un_Modal M ON M.ModalID=U.ModalID
							INNER JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
							INNER JOIN dbo.Un_Oper O ON O.OperID = CT.OperID
							INNER JOIN dbo.Un_OperType OT ON OT.OperTypeID = O.OperTypeID
							INNER JOIN dbo.Un_Plan p ON p.PlanID = M.planID
							INNER JOIN dbo.Un_Convention c ON c.ConventionID = U.ConventionID
							LEFT OUTER JOIN dbo.Un_TIN T ON T.OperID = O.OperID
							LEFT OUTER JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID 
							LEFT OUTER JOIN dbo.Mo_Company cie ON cie.CompanyID = EP.ExternalPromoID
						 WHERE
						    U.IntReimbDate IS NULL AND  
						    U.ConventionID = @iIDConvention 
                            AND (CT.EffectDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())) --Date debut et fin d'opperation			
					    
					END
				ELSE
					BEGIN
						 INSERT INTO @tUn_CotisationsFraisConvention
						 (
							mCotisation,dtDateEffective,iIDGroupeUnite,fQteUnite,
							iID_Cotisation,mFrais,iID_Oper,dtDateOperation,vcTypeOperation,
							vcCompagnie,mAutreRev,iIDConvention,iPayementParAnnee,iNombrePayement
						)
						 SELECT CT.Cotisation,
								CT.EffectDate,
								CT.UnitID,
								U.UnitQty,
								CT.CotisationID,
								CASE	
										WHEN p.PlanTypeID = 'IND' THEN 
											CASE
												WHEN UPPER(LEFT(CAST(c.ConventionNo AS VARCHAR(15)),1)) IN ('I','F') THEN 200
												WHEN UPPER(LEFT(CAST(c.ConventionNo AS VARCHAR(15)),1)) = 'T' THEN
													-- FT1
													--CASE
													--	WHEN DATEDIFF(mm,@dtMinOperDate, @dtDateFin) <= @iNb_Mois_Avant_RIN_Apres_RIO THEN 200
													--	ELSE 0
													--END
													CASE
														WHEN (SELECT dbo.fnGENE_ObtenirParametre (
																				'OPER_VALIDATION_12_MOIS'
																				,@dtMinOperDate
																				,NULL
																				,NULL
																				,NULL
																				,NULL
																				,NULL)) = 1 THEN
															CASE
																WHEN DATEDIFF(mm,@dtMinOperDate, @dtDateFin) <= @iNb_Mois_Avant_RIN_Apres_RIO THEN 
																	200
																ELSE 
																	0
															END
														ELSE
															0
													END

												ELSE	
													CT.Fee	
											END																				
										ELSE
											CT.Fee
								END,
								CT.OperID,
								O.OperDate,
								O.OperTypeID,
								Company = CASE O.OperTypeID
										  WHEN 'TIN' THEN ISNULL(cie.CompanyName,'')
										  ELSE
										  ''
										  END,
								0,
								conventionid = U.ConventionID,
								M.pmtByYearID,
								M.pmtQty
						  FROM 
							dbo.Un_Unit U
							INNER JOIN dbo.Un_Modal M ON M.ModalID=U.ModalID
							INNER JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
							INNER JOIN dbo.Un_Oper O ON O.OperID = CT.OperID
							INNER JOIN dbo.Un_OperType OT ON OT.OperTypeID = O.OperTypeID
							INNER JOIN dbo.Un_Plan p ON p.PlanID = M.planID
							INNER JOIN dbo.Un_Convention c ON c.ConventionID = U.ConventionID
							LEFT OUTER JOIN dbo.Un_TIN T ON T.OperID = O.OperID
							LEFT OUTER JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID 
							LEFT OUTER JOIN dbo.Mo_Company cie ON cie.CompanyID = EP.ExternalPromoID
						 WHERE 
						--20111129 MBD PAS NECESSAIRE DANS LE CALCUL DU SOLDE INITIAL
						--Mbaye Diakhate: 2011-12-19: changer la condition  pour  prendre en compte les groupes d'unitéé résilié durant la période
						--U.TerminatedDate IS NULL
						(U.TerminatedDate IS NULL OR (U.TerminatedDate >=@dtDateDebut AND U.TerminatedDate <=@dtDateFin)) 
						 AND 
						U.IntReimbDate IS NULL AND U.ConventionID = @iIDConvention 
							AND (CT.UnitID = ISNULL(@iGroupeUnite,CT.UnitID) )--ID du groupe d'unité
							AND (CT.EffectDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())) --Date debut et fin d'opperation			
					     --20111129 MBD AJOUT DE GROUPE BY POUR PRENDRE EN COMPTE LES OPERATIONS DES AUTRES GROUPE D'UNITE
					     --GROUP BY CT.OperID,CT.Cotisation,CT.EffectDate,CT.UnitID,U.UnitQty,CT.CotisationID,p.PlanTypeID,c.ConventionNo,CT.Fee,O.OperDate,O.OperTypeID,cie.CompanyName,U.ConventionID,M.pmtByYearID,M.pmtQty
					END
			END
		END                       
	ELSE
		BEGIN
			--Recherche des frais et cotisations
			IF @iIDConvention IS NOT NULL AND @vcTypeDate IS NOT NULL
			 BEGIN
				 IF @vcTypeDate = 'O'
					 BEGIN
						 INSERT INTO @tUn_CotisationsFraisConvention
						 (
							mCotisation,dtDateEffective,iIDGroupeUnite,fQteUnite,iID_Cotisation,mFrais,
							iID_Oper,dtDateOperation,vcTypeOperation,vcCompagnie,mAutreRev,iIDConvention,
							iPayementParAnnee,iNombrePayement
						)
						 SELECT 
								ISNULL(CT.Cotisation,0),CT.EffectDate,CT.UnitID,ISNULL(U.UnitQty,0),CT.CotisationID, ISNULL(CT.Fee,0),CT.OperID,O.OperDate,O.OperTypeID, Company = CASE O.OperTypeID WHEN 'TIN' THEN ISNULL(C.CompanyName,'') ELSE '' END, fAIP,ConventionID = U.ConventionID,M.pmtByYearID,M.pmtQty
         				  FROM 
								dbo.Un_Unit U
								INNER JOIN dbo.Un_Modal M ON M.ModalID=U.ModalID
								INNER JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
		 						INNER JOIN dbo.Un_Oper O ON O.OperID = CT.OperID
								INNER JOIN dbo.Un_OperType OT ON OT.OperTypeID = O.OperTypeID
								LEFT OUTER JOIN dbo.Un_TIN T ON T.OperID = O.OperID
								LEFT OUTER JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID 
								LEFT OUTER JOIN dbo.Mo_Company C ON C.CompanyID = EP.ExternalPromoID
						 WHERE 
						   --Mbaye Diakhate: 2011-12-19: changer la condition  pour  prendre en compte les groupes d'unitéé résilié durant la période
						   --U.TerminatedDate IS NULL
						   (U.TerminatedDate IS NULL OR (U.TerminatedDate >=@dtDateDebut AND U.TerminatedDate <=@dtDateFin)) 
							AND U.IntReimbDate IS NULL AND U.ConventionID = @iIDConvention
							AND (CT.UnitID = ISNULL(@iGroupeUnite,CT.UnitID))--ID du groupe d'unité
							AND (O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())) --Date debut et fin d'opperation
					END
				ELSE
					BEGIN
						 INSERT INTO @tUn_CotisationsFraisConvention
						 (
							mCotisation,dtDateEffective,iIDGroupeUnite,fQteUnite,iID_Cotisation,mFrais,iID_Oper,
							dtDateOperation,vcTypeOperation,vcCompagnie,mAutreRev,iIDConvention,iPayementParAnnee,iNombrePayement
						)
						 SELECT 
								CT.Cotisation,CT.EffectDate,CT.UnitID,U.UnitQty,CT.CotisationID,
								CT.Fee,CT.OperID,O.OperDate,O.OperTypeID,Company =	CASE O.OperTypeID 
																					WHEN 'TIN' THEN ISNULL(C.CompanyName,'') 
																					WHEN 'OUT' THEN ISNULL(COUT.CompanyName,'') 
																					ELSE '' END,
								0,conventionid = U.ConventionID,M.pmtByYearID,M.pmtQty
						  FROM 
							dbo.Un_Unit U
							INNER JOIN dbo.Un_Modal M ON M.ModalID=U.ModalID
							INNER JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
							INNER JOIN dbo.Un_Oper O ON O.OperID = CT.OperID
							INNER JOIN dbo.Un_OperType OT ON OT.OperTypeID = O.OperTypeID
							LEFT OUTER JOIN dbo.Un_TIN T ON T.OperID = O.OperID
							LEFT OUTER JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID 
							LEFT OUTER JOIN dbo.Mo_Company C ON C.CompanyID = EP.ExternalPromoID
							LEFT OUTER JOIN dbo.Un_OUT TOUT ON TOUT.OperID = O.OperID
							LEFT OUTER JOIN dbo.Un_ExternalPlan EPOUT ON EPOUT.ExternalPlanID = TOUT.ExternalPlanID 
							LEFT OUTER JOIN dbo.Mo_Company COUT ON COUT.CompanyID = EPOUT.ExternalPromoID
						 WHERE 
						   --Mbaye Diakhate: 2011-12-19: changer la condition  pour  prendre en compte les groupes d'unitéé résilié durant la période
						   --U.TerminatedDate IS NULL
						   (U.TerminatedDate IS NULL OR (U.TerminatedDate >=@dtDateDebut AND U.TerminatedDate <=@dtDateFin)) 
						 	AND 
							U.IntReimbDate IS NULL AND U.ConventionID = @iIDConvention AND (CT.UnitID = ISNULL(@iGroupeUnite,CT.UnitID) )--ID du groupe d'unité
							AND (CT.EffectDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())) --Date debut et fin d'opperation			
	                   --20111129 MBD AJOUT DE GROUPE BY POUR PRENDRE EN COMPTE LES OPERATIONS DES AUTRES GROUPE D'UNITE
					   --GROUP BY CT.OperID,CT.Cotisation,CT.EffectDate,CT.UnitID,U.UnitQty,CT.CotisationID,CT.Fee,O.OperDate,O.OperTypeID,C.CompanyName,fAIP,U.ConventionID,M.pmtByYearID,M.pmtQty
				
					END
			END
		END
		
	--Ajouter le filtre de la categorie d'operation  
	IF @vcCodeCategorie IS NOT NULL
		BEGIN
			DELETE FROM @tUn_CotisationsFraisConvention
			WHERE NOT EXISTS(	SELECT 1
								FROM 
									dbo.tblOPER_CategoriesOperation CO 
								WHERE 
									CO.vcCode_Categorie = @vcCodeCategorie )
		END 
   */
   RETURN 
   
END