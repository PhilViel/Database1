/****************************************************************************************************
Code de service		:	fnPCEE_ObtenirSubventionBons
Nom du service		:	Obtenir les subvention et bons d’étude    
But					:	Récupérer la liste des Subventions et des bons d’étude
Facette				:	P171U
Reférence			:	Relevé de dépôt
Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
                        iIdConvention	            Identifiant unique de la convention         Oui
                        dtDateDebut	                Date du début du relevé des cotisations     Non
                        dtDateFin	                Date de fin du relevé des cotisations       Non

Exemple d'appel:
                
              SELECT * FROM fntPCEE_ObtenirSubventionBons (12542,NULL,NULL)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Un_CESP	                    fCESG	                                    SCEE  reçue (+), versée (-) ou remboursée (-)
						Un_CESP	                    fACESG	                                    SCEE+ reçue (+), versée (-) ou remboursée (-)
						Un_CESP	                    fCLB	                                    BEC reçu (+), versé (-) ou remboursé (-)
						Un_CESP	                    fPG	                                        Subvention provinciale reçue (+), versée (-) ou remboursée (-)
						Un_CESP	                    vcPGProv	                                Province d'où provient la subvention provinciale

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-04					Fatiha Araar							Création de la fonction           
						2008-03-05					Dan Trifan								Ajout IS+ et INS
						2009-05-01					Jean-François Gauthier					Correction d'un produit cartésien sur les Left Join					
						2009-05-05					Jean-François Gauthier					Ajout d'une UNION pour récupérer
																							les intérêts PAE n'étant pas dans Un_CESP
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntPCEE_ObtenirSubventionBons]
					(	
						@iIdConvention INT,
						@dtDateDebut DATETIME,
						@dtDateFin DATETIME
					)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		fCESG		= CE.fCESG,	-- SCEE reçue (+), versée (-) ou remboursée (-)
		fACESG		= CE.fACESG,	-- SCEE+ reçue (+), versée (-) ou remboursée (-)
		fCLB		= CE.fCLB,		-- BEC reçu (+), versé (-) ou remboursé (-)
		fPG			= CE.fPG,		-- Subvention provinciale reçue (+), versée (-) ou remboursée (-)
		fCESGINT	= ISNULL(COP1.ConventionOperAmount,0),
		fACESGINT	= ISNULL(COP2.ConventionOperAmount,0),
		ConventionID = C.ConventionID,
		O.OperID -- operationID
	FROM	
		dbo.Un_Convention C
		INNER JOIN dbo.Un_CESP CE 
			ON C.ConventionID = CE.ConventionID
		INNER JOIN Un_Oper O 
			ON O.OperID = CE.OperID
		LEFT JOIN Un_ConventionOper COP1 
			ON COP1.OperID = O.OperID AND (COP1.ConventioNID = C.ConventionID) AND COP1.ConventionOperTypeID  = 'INS'
		LEFT JOIN Un_ConventionOper COP2 
			ON COP2.OperID = O.OperID AND (COP2.ConventionID = C.ConventionID) AND COP2.ConventionOperTypeID  = 'IS+'
	WHERE 
		C.ConventionID = @iIdConvention 
		AND 
		O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
	UNION ALL
	SELECT 
		fCESG			= 0,		-- SCEE reçue (+), versée (-) ou remboursée (-)
		fACESG			= 0,		-- SCEE+ reçue (+), versée (-) ou remboursée (-)
		fCLB			= 0,		-- BEC reçu (+), versé (-) ou remboursé (-)
		fPG				= 0,		-- Subvention provinciale reçue (+), versée (-) ou remboursée (-)
		fCESGINT		= ISNULL(COP1.ConventionOperAmount,0),
		fACESGINT		= ISNULL(COP2.ConventionOperAmount,0),
		ConventionID	= C.ConventionID,
		COP1.OperID					-- operationID
	FROM	
		dbo.Un_Convention C
		LEFT JOIN Un_ConventionOper COP1 
			ON (COP1.ConventioNID = C.ConventionID) AND COP1.ConventionOperTypeID  = 'INS'
		LEFT JOIN Un_ConventionOper COP2 
			ON (COP2.ConventionID = C.ConventionID) AND COP2.ConventionOperTypeID  = 'IS+'
		INNER JOIN dbo.Un_Oper O
			ON COP1.OperID = O.OperID 
	WHERE 
		O.OperTypeID = 'PAE'
		AND
		C.ConventionID = @iIdConvention 
		AND 
		O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())	
		AND
		O.OperID NOT IN (	
								SELECT 
									DISTINCT O.OperID 
								FROM	
									dbo.Un_Convention C
									INNER JOIN dbo.Un_CESP CE 
										ON C.ConventionID = CE.ConventionID
									INNER JOIN Un_Oper O 
										ON O.OperID = CE.OperID
									LEFT JOIN Un_ConventionOper COP1 
										ON COP1.OperID = O.OperID AND (COP1.ConventioNID = C.ConventionID) AND COP1.ConventionOperTypeID  = 'INS'
									LEFT JOIN Un_ConventionOper COP2 
										ON COP2.OperID = O.OperID AND (COP2.ConventionID = C.ConventionID) AND COP2.ConventionOperTypeID  = 'IS+'
								WHERE 
									C.ConventionID = @iIdConvention 
									AND 
									O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
							 )
)