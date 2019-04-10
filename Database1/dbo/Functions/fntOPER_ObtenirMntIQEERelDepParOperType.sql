/****************************************************************************************************
Code de service		:		fntOPER_ObtenirMntIQEERelDepParOperType
Nom du service		:		Obtenir les montants d'IQÉÉ pour un type d'operation
But					:		Récupérer le solde d’IQÉÉ et d’intérêts IQÉÉ à une date donnée pour un type d'opération.
Facette				:		IQEE

Parametres d'entrée :	Parametres					Description                             Obligatoire
                        ----------                  ----------------                        --------------                       
                        @iIdConvention	            Identifiant unique de la convention		Oui
                        @dtDateDebutReleve			Date de début du relevé					Non	(Défaut = 1900-01-01)
						@dtDateFinReleve			Date de fin du relevé de dépôt			Non (Défaut = date du jour)
						@vcOperTypeID			    Type d'opération            			Oui 

Exemple d'appel:        
						SELECT * FROM fntOPER_ObtenirMntIQEERelDepParOperType(349129, '2010-01-01', '2010-12-31','OUT')
						

Parametres de sortie :  Table						Champs							Description
					    -----------------			---------------------------		--------------------------
                        N/A							mMntIQEE						Montant IQEE
													mMntIntIQEE						Montant d'intérêts IQEE
													mMntIQEEMaj						Montant d'IQEE majoré
													mMntIQEECdb						Montant du crédit de base de l'IQEE
													iIDConvention					Identitifiant de la convention
                        
Historique des modifications :
						Date		Programmeur								Description
						----------	-------------------------------------	-------------------------------------------------
						2012-01-11	Mbaye Diakhate      					Création de la fonction
																			
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirMntIQEERelDepParOperType]
(	
    @iIdConvention		INT
	,@dtDateDebutReleve	DATETIME
	,@dtDateFinReleve	DATETIME
	,@vcOperTypeID	    CHAR(3)
)
RETURNS  @tIQEE TABLE
(
	mMntIQEE		MONEY
	,mMntIntIQEE	MONEY
	,mMntIQEEMaj	MONEY
	,mMntIQEECdb	MONEY
	,mMntIQEEPae	MONEY
	,mMntIntIQEEPae MONEY
	,iIDConvention	INT

)
BEGIN
	DECLARE @mMntIQEE					MONEY
			,@mMntIntIQEE				MONEY
			,@mMntIQEEMaj				MONEY
			,@mMntIQEECdb				MONEY
			,@mMntIQEEPae				MONEY
			,@mMntIntIQEEPae			MONEY

	INSERT INTO @tIQEE
	(
		mMntIQEE
		,mMntIntIQEE
		,mMntIQEEMaj	
		,mMntIQEECdb
		,mMntIQEEPae
		,mMntIntIQEEPae
		,iIDConvention
	
	)
	SELECT
		ISNULL(SUM(tmp.mMntIQEE),0)
		,ISNULL(SUM(tmp.mMntIntIQEE),0)	
		,ISNULL(SUM(tmp.mMntIQEEMaj),0)	
		,ISNULL(SUM(tmp.mMntIQEECdb),0)	
		,mMntIQEEPae	=	 (
									SELECT	
										mIQEEPAE = SUM(CO.ConventionOperAmount)
									FROM 
										dbo.Un_ConventionOper CO
										INNER JOIN dbo.Un_Oper O 
											ON O.OperID=CO.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebutReleve,'1900-01-01') AND ISNULL(@dtDateFinReleve, GETDATE())
									WHERE 
										CO.ConventionID = @iIdConvention 
										AND
										O.OperTypeID = @vcOperTypeID
										AND
										co.ConventionOperTypeId IN (
																	SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE')
																	UNION
																	SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE')
																	UNION
																	SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION')
																	)
									--Mbaye Diakhate: enlevé le group by car il retourne plusieur ligne et cela bloque le traitement batch cas  Kezerli, vorinique
									--GROUP BY 
									--	CO.ConventionID,
									--	O.OperTypeID, 
									--	CO.OperID,
									--	O.OperDate
								 )
		,mMntIntIQEEPae	=		(
									SELECT	
										mIQEEPAE = SUM(CO.ConventionOperAmount)
									FROM 
										dbo.Un_ConventionOper CO
										INNER JOIN dbo.Un_Oper O 
											ON O.OperID=CO.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebutReleve,'1900-01-01') AND ISNULL(@dtDateFinReleve, GETDATE())
									WHERE 
										CO.ConventionID = @iIdConvention 
										AND
										O.OperTypeID = @vcOperTypeID
										AND
										co.ConventionOperTypeId IN (SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE'))
								--Mbaye Diakhate: enlevé le group by car il retourne plusieur ligne et cela bloque le traitement batch cas  Kezerli, vorinique
									--GROUP BY 
									--	CO.ConventionID,
									--	O.OperTypeID, 
									--	CO.OperID,
									--	O.OperDate
								 )
		,@iIdConvention
		
	FROM
		(
		SELECT 
			mMntIQEE		=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_IQEE') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			,mMntIntIQEE	=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			,mMntIQEEMaj	=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			,mMntIQEECdb	=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			
		FROM 
			dbo.Un_ConventionOPER co
			INNER JOIN dbo.Un_OPER o
				ON co.OperID = o.OperID
		WHERE 
			 co.ConventionID = @iIdConvention
			 AND
			 o.OperDate BETWEEN ISNULL(@dtDateDebutReleve,'1900-01-01') AND ISNULL(@dtDateFinReleve, GETDATE())
			 AND
			 o.OperTypeID = @vcOperTypeID	
			 
		) AS tmp
	RETURN
END