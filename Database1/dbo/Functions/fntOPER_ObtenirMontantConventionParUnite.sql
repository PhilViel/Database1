﻿
/****************************************************************************************************
Code de service		:		fntOPER_ObtenirMontantConventionParUnite
Nom du service		:		Obtenir les intérets sur les montants souscrits    
But					:		Récupérer le montant d’intérêts sur un montant souscrit
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
                        iIdConvention	            Identifiant unique de la convention         Oui
						dtDateDebut	                Date de début
						dtDateFin	                Date de fin
						vcCodeCategorie	            Catégorie d’opérations à renvoyer

Exemple d'appel:
                
                SELECT * FROM dbo.fntOPER_ObtenirMontantConventionParUnite (125647,NULL,'2008-12-31','INT_PCEE_TIN_TFR')

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Un_ConventionOper	        ConventionOperAmount	                    Montant de l’interet
						Un_ConventionOper	        ConventionOperDate	                        Date de l’opération sur la convention
						Un_Oper	                    mFrais	                                    Frais
						Un_Oper	                    iID_Oper	                                Identifiant unique de l’opération
						Un_Oper	                    OperDate	                                Date de l’opération
						Un_Oper	                    OperTypeID	                                Type d’opération

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-01					Jean-François Gauthier					Création de la procédure
****************************************************************************************************/

CREATE FUNCTION [dbo].[fntOPER_ObtenirMontantConventionParUnite]
						( @iIdConvention INT,
						  @dtDateDebut DATETIME,
						  @dtDateFin DATETIME,
						  @vcCodeCategorie VARCHAR(100))
RETURNS  @tMontantInterets 
	TABLE	( 
			ConventionOperAmount	MONEY,
			OperDate				DATETIME,
			iID_Oper				INT,
			OperTypeID				CHAR(3),
			ConventionOperTypeID	CHAR(3),
			ConventionID			INT,
			iIDUnit					INT
			)
BEGIN
	IF @dtDateDebut IS NULL 
		BEGIN
			SET @dtDateDebut = '1900/01/01'
		END

	IF @dtDateFin IS NULL 
		BEGIN
			SET @dtDateFin = GETDATE()
		END

	IF @vcCodeCategorie IS NULL
		INSERT INTO @tMontantInterets
		(
			ConventionOperAmount,
			OperDate,
			iID_Oper,
			OperTypeID,
			ConventionOperTypeID,
			ConventionID,
			iIDUnit
		)
		SELECT 
			ConventionOperAmount = CO.ConventionOperAmount,--Montant de l’interet
			OperDate = O.OperDate,--Date de l'operation
			iID_Oper = O.Operid,--l'id de l'operation
			OperTypeID = O.OperTypeID,--le type de l'operation
			ConventionOperTypeID = ConventionOperTypeID,
			conventionid = CO.ConventionID,
			u.UnitID
		FROM
			dbo.Un_Unit u
			INNER JOIN dbo.Un_ConventionOper CO
				ON u.ConventionID = CO.ConventionID
			INNER JOIN dbo.Un_Oper O 
				ON O.OperID = CO.OperID
		WHERE 
			(O.OperDate >= @dtDateDebut AND O.OperDate <=  @dtDateFin)
			AND 
			CO.ConventionID  = @iIdConvention 
	ELSE 
		INSERT INTO @tMontantInterets
		(
			ConventionOperAmount,
			OperDate,
			iID_Oper,
			OperTypeID,
			ConventionOperTypeID,
			ConventionID,
			iIDUnit
		)
		 SELECT 
				ConventionOperAmount = CO.ConventionOperAmount,--Montant de l’interet
				OperDate = O.OperDate,--Date de l'operation
				iID_Oper = O.Operid,--l'id de l'operation
				OperTypeID = O.OperTypeID,--le type de l'operation
				ConventionOperTypeID = ConventionOperTypeID,
				conventionid = CO.ConventionID,
				u.UnitID
		   FROM 
				dbo.Un_Unit u
				INNER JOIN dbo.Un_ConventionOper CO
					ON u.ConventionID = CO.ConventionID
				INNER JOIN dbo.Un_Oper O 
					ON O.OperID = CO.OperID
				INNER JOIN dbo.tblOPER_OperationsCategorie OC 
					ON OperTypeID = OC.cID_Type_Oper AND ConventionOperTypeID = OC.cID_Type_Oper_Convention
				INNER JOIN dbo.tblOPER_CategoriesOperation COP 
					ON COP.iID_Categorie_Oper = OC.iID_Categorie_Oper AND COP.vcCode_Categorie = @vcCodeCategorie 
		  WHERE 
			(O.OperDate >= @dtDateDebut AND O.OperDate <=  @dtDateFin)
			AND 
			CO.ConventionID  = @iIdConvention 

	RETURN
END
