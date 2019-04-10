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
Code de service		:	fntPCEE_ObtenirSubventionBonsParUnite
Nom du service		:	Obtenir les subvention et bons d’étude par Unité 
But					:	Récupérer la liste des Subventions et des bons d’étude par Unité
Facette				:	P171U
Reférence			:	Relevé de dépôt
Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
                        iIdConvention	            Identifiant unique de la convention         Oui
                        dtDateDebut	                Date du début du relevé des cotisations     Non
                        dtDateFin	                Date de fin du relevé des cotisations       Non

Exemple d'appel:
                
              SELECT * FROM dbo.fntPCEE_ObtenirSubventionBonsParUnite (230242,NULL,'2010-12-31')

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
						2009-10-02					Jean-François Gauthier					Création de la fonction           
						2009-10-09					Jean-François Gauthier					Modification afin d'intéger la table Un_Cotisation dans la requête
						2010-08-17					Jean-François Gauthier					Modification du JOIN sur Un_CESP, car certaines opérations
																							ne sont pas récupérées si on passe par les cotisations
                        2018-08-30                  Pierre-Luc Simard                       N'est plus utilisée
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntPCEE_ObtenirSubventionBonsParUnite]
					(	
						@iIdConvention INT,
						@dtDateDebut DATETIME,
						@dtDateFin DATETIME
					)
RETURNS TABLE 
AS
RETURN 
(
    
    SELECT Deprecated = 1/0

    /*
	SELECT 
		fCESG		= CE.fCESG,	-- SCEE reçue (+), versée (-) ou remboursée (-)
		fACESG		= CE.fACESG,	-- SCEE+ reçue (+), versée (-) ou remboursée (-)
		fCLB		= CE.fCLB,		-- BEC reçu (+), versé (-) ou remboursé (-)
		fPG			= CE.fPG,		-- Subvention provinciale reçue (+), versée (-) ou remboursée (-)
		fCESGINT	= ISNULL(COP1.ConventionOperAmount,0),
		fACESGINT	= ISNULL(COP2.ConventionOperAmount,0),
		ConventionID = C.ConventionID,
		O.OperID,
		u.UnitID
	FROM
		dbo.Un_Unit u
		INNER JOIN dbo.Un_Cotisation co
			ON u.UnitID = co.UnitID 
		INNER JOIN dbo.Un_Convention C
			ON u.ConventionID = C.ConventionID	
		INNER JOIN dbo.Un_CESP CE 
			ON C.ConventionID = CE.ConventionID AND CE.CotisationID =  co.CotisationID -- 2010-08-17 : JFG
		INNER JOIN Un_Oper O 
			ON O.OperID = CE.OperID
		LEFT OUTER JOIN Un_ConventionOper COP1 
			ON COP1.OperID = O.OperID AND (COP1.ConventioNID = C.ConventionID) AND COP1.ConventionOperTypeID  = 'INS'
		LEFT OUTER JOIN Un_ConventionOper COP2 
			ON COP2.OperID = O.OperID AND (COP2.ConventionID = C.ConventionID) AND COP2.ConventionOperTypeID  = 'IS+'
	WHERE 
		C.ConventionID = @iIdConvention 
		AND 
		O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
		AND
		o.OperTypeID <> 'ANN'
	UNION ALL
	SELECT 
		fCESG		= ce.fCESG,	-- SCEE reçue (+), versée (-) ou remboursée (-)
		fACESG		= ce.fACESG,	-- SCEE+ reçue (+), versée (-) ou remboursée (-)
		fCLB		= ce.fCLB,		-- BEC reçu (+), versé (-) ou remboursé (-)
		fPG			= ce.fPG,		-- Subvention provinciale reçue (+), versée (-) ou remboursée (-)
		fCESGINT	= 0,
		fACESGINT	= 0,
		ConventionID = c.ConventionID,
		oc.OperSourceID,
		UnitId = (SELECT ct.UnitID FROM dbo.Un_Cotisation ct WHERE ct.OperID = oc.OperSourceId)
	FROM 
		dbo.Un_Oper o
		INNER JOIN dbo.Un_OperCancelation  oc
			ON o.OperId = oc.OperId
		INNER JOIN dbo.Un_CESP ce
			ON oc.OperId = ce.OperId
		INNER JOIN dbo.Un_Convention c
			ON c.ConventionID = ce.ConventionID 
	WHERE 
		c.ConventionID = @iIdConvention 
		AND 
		o.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
		AND 
		o.OperTypeId = 'ANN'
    */
)